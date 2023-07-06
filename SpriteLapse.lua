require 'config'

 --- Constructs an SpriteLapse object, responsible for managing (adding and removing frames) the timelapse of the passed source sprite.
 --- fails if the source sprite is another timelapse sprite managed by another SpriteLapse instance.
 --- Also responsible for managing a dialog object that allows the user to edit this very sprite lapse instance.
 ---@param source_sprite Sprite
 --- the sprite that frames should be taken from, when updating the timelapse
 ---@return SpriteLapse | nil
 --- returns an SpriteLapse instance, if the object was created succesfully, otherwise nil is returned.
 function SpriteLapse(source_sprite)
    
    local spritelapse = {
        --- instance of the sprite frames are being taken from.
        source_sprite = nil,
        lapse_dialog = nil,
        
        --- constructor helper method, see SpriteLapse function for info
        __init__ = function(self, _source_sprite)
            
            self.source_sprite = _source_sprite
            
            app.transaction(function()
                
                -- each sprite which has a timelapse, will be marked with the has_lapse property.
                -- this signals to the extension that on future loads, the following sprite should automatically be registered in the extension.
                
                self.source_sprite.properties(PLUGIN_KEY).has_lapse = true
                
                -- has_dialog represents whether the current sprite should have its lapse_dialog visible to the user
                if self.source_sprite.properties(PLUGIN_KEY).has_dialog == nil then
                    self.source_sprite.properties(PLUGIN_KEY).has_dialog = false
                end
                
                -- is_paused controls whether frames are stored, on sprite modifications
                if self.source_sprite.properties(PLUGIN_KEY).is_paused == nil then
                    self.source_sprite.properties(PLUGIN_KEY).is_paused = true
                end
                
            end)
            
            -- load any previously stored timelapse frames into memory
            
            if app.fs.isFile(self:__timelapseFile()) then
                self:__loadLapse(self:__timelapseFile())
            end
            
            -- setup dialog
            
            self.lapse_dialog = Dialog {
                title = "Timelapse",
                onclose = function()
                    if self.__user_closed then
                        
                        -- we do not want to store proeprties change events, as those are not visual,
                        -- so we immediatly erase the newly stored frame, after modifying the sprite properties
                        
                        self.source_sprite.properties(PLUGIN_KEY).has_dialog = false
                        
                        self:__removeFrame()
                    end
                end
            }
            :label
            {
                id = "frameCount",
                text = "Frames: " .. #self.__frames,
            }
            :button
            {
                id="generateTimelapse",
                text="Generate",
                onclick = function()
                    self:__generateTimelapse()
                end
            }
            :button
            {
                id="playPauseButton",
                onclick = function()
                    self:__togglePause()
                    self:__syncPlayPauseButton()
                end,
            }
            
            self:__syncPlayPauseButton()
            
            -- store a copy of the sprite in memory, every time the sprite is modified, unless the timelapse is paused
            
            self.__sprite_event_key = self.source_sprite.events:on('change',
            function(ev)
                if self.source_sprite.properties(PLUGIN_KEY).is_paused then
                    return
                end
                
                self:__storeFrame(app.frame)
            end)

            return self
        end,

        --- Should be invoked whenever the SpriteLapse is no longer needed.
        --- Saves a copy of the current timelapse to disk.
        cleanup = function(self)
            self:__generateTimelapse():close()
        end,
        
        --- Called any time the source_sprite is focused or not
        focus = function(self, focused)
            
            -- the dialog should only be visible to the user, if the source_sprite is focused, and has_dialog is set.
            
            if focused and self.source_sprite.properties(PLUGIN_KEY).has_dialog then
                self.lapse_dialog:show{ wait = false }
            else
                -- __user_closed is used in the onclose method, to decide whether has_dialog should be cleared or not.
                self.__user_closed = false
                self.lapse_dialog:close()
                self.__user_closed = true
            end
        end,
        
        --- Shows the lapse_dialog dialog.
        openDialog = function(self)
            self.source_sprite.properties(PLUGIN_KEY).has_dialog = true
            self:__removeFrame()

            self.lapse_dialog:show{ wait = false }
        end,
        
        __user_closed = true,
        __sprite_event_key = nil,
        -- list of Image objects, representing a frame in the timelapse.
        __frames = {},

        --- Toggle the pause state of the SpriteLapse instance
        __togglePause = function(self)
            self.source_sprite.properties(PLUGIN_KEY).is_paused = not self.source_sprite.properties(PLUGIN_KEY).is_paused
            
            -- we only remove the frame here, if it was previously paused,
            -- as the modification to the is_paused property would be seen in the sitechange event,
            -- resulting in frames not being stored whenever we go from unpaused to paused
            if not self.source_sprite.properties(PLUGIN_KEY).is_paused then
                self:__removeFrame()
            end
        end,

        --- Update the text of the playPauseButton so it matches with the pause state.
        ---@param self any
        __syncPlayPauseButton = function(self)
            if self.source_sprite.properties(PLUGIN_KEY).is_paused then
                self.lapse_dialog:modify{
                    id="playPauseButton",
                    text = "►"
                }
            else
                self.lapse_dialog:modify{
                    id="playPauseButton",
                    text = "||"
                }
            end
        end,

        --- Inserts a copy of the passed frame from the source sprite, into a new frame in the lapse_sprite.
        ---@param self any
        ---@param frame any
        --- the frame that should be copied from, if source_sprite is the active sprite, app.frame should be used.
        __storeFrame = function(self, frame)
            local new_image = Image(self.source_sprite.spec)

            new_image:drawSprite(self.source_sprite, frame.frameNumber)

            table.insert(self.__frames, new_image)

            self.lapse_dialog:modify{
                id = "frameCount",
                text = "Frames: " .. #self.__frames,
            }
        end,

        --- Removes the latest frame from the timelapse memory.
        __removeFrame = function(self)
            table.remove(self.__frames, #self.__frames)
                self.lapse_dialog:modify{
                    id = "frameCount",
                    text = "Frames: " .. #self.__frames,
                }
        end,

        --- Creates a new sprite which holds the timelapse frame currently stored in memory
        ---@return Sprite
        --- The generated sprite
        __generateTimelapse = function(self)
            
            -- find the width and height of the sprite,
            -- it should be large enough to hold both the tallest and widest image currently in memory.

            local max_width, max_height = 0, 0
            
            local color_mode = nil

            if #self.__frames > 0 then
                color_mode = self.__frames[1].colorMode
            end

            for _, frame in ipairs(self.__frames) do
                max_width = math.max(max_width, frame.width)
                max_height = math.max(max_width, frame.height)
            end

            local sprite = Sprite(max_width, max_height, color_mode)
            
            -- convert the currently stored images in __frames to frames in the sprite

            for frame_number, frame_image in ipairs(self.__frames) do
                local frame = sprite:newEmptyFrame(frame_number)
                sprite:newCel(sprite.layers[1], frame, frame_image)
            end

            -- whenever a Sprite is constructed, it comes with an empty frame, so this frame is removed here.

            sprite:deleteFrame(#sprite.frames)

            -- finally save the timelapse sprite to disk

            sprite.filename = self:__timelapseFile()
            
            sprite:saveAs(sprite.filename)

            return sprite
        end,

        --- Returns the name of the source_sprite suffixed with '-lapse'
        ---@return string
        --- Timelapse filename
        __timelapseFile = function(self)
            local name, ext = self.source_sprite.filename:match("^(.*)(%..*)$")

            return name .. "-lapse" .. ext
        end,

        --- Loads all frames of the given sprite, stored at file_name into the __frames list.
        ---@param file_name any
        __loadLapse = function(self, file_name)
            
            -- open the sprite which has all of the frames

            local timelapse_sprite = Sprite{ fromFile = self:__timelapseFile() }

            -- load all of the frames into memory

            for _, cel in ipairs(timelapse_sprite.cels) do
                -- we create a new image instance here, as the cel.image will reference an invalid Image when we close the timelapse_sprite
                table.insert(self.__frames, Image(cel.image))
            end

            -- close the sprite now

            timelapse_sprite:close()
        end,
    }

    return spritelapse:__init__(source_sprite)
end
