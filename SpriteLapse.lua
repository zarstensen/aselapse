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

                self.source_sprite.properties(PLUGIN_KEY).has_lapse = true
                
                if self.source_sprite.properties(PLUGIN_KEY).has_dialog == nil then
                    self.source_sprite.properties(PLUGIN_KEY).has_dialog = false
                end

                if self.source_sprite.properties(PLUGIN_KEY).is_paused == nil then
                    self.source_sprite.properties(PLUGIN_KEY).is_paused = true
                end

            end)

            -- determine which way to retrieve the lapse_sprite instance, based on the state of the source sprite

            if app.fs.isFile(self:__timelapseFile()) then
                self:__loadLapse(self:__timelapseFile())
            end

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
                id="toggleRecordButton",
                onclick = function()
                    self:__togglePause()
                    self:__syncPauseButton()
                end,
            }

            self:__syncPauseButton()

            self.__sprite_event_key = self.source_sprite.events:on('change',
                function(ev)
                    if self.source_sprite.properties(PLUGIN_KEY).is_paused then
                        return
                    end

                    self:__storeFrame(app.frame)
                end)

            return self
        end,
        
        focus = function(self, focused)
            if focused and self.source_sprite.properties(PLUGIN_KEY).has_dialog then
                self.lapse_dialog:show{ wait = false }
            else
                self.__user_closed = false
                self.lapse_dialog:close()
                self.__user_closed = true
            end
        end,
        
        openDialog = function(self)
            self:__removeFrame()
            self.source_sprite.properties(PLUGIN_KEY).has_dialog = true
            self.lapse_dialog:show{ wait = false }
        end,
        
        __user_closed = true,
        __prev_dialog_state = nil,
        __sprite_event_key = nil,
        __frames = {},

        __togglePause = function(self)
            self.source_sprite.properties(PLUGIN_KEY).is_paused = not self.source_sprite.properties(PLUGIN_KEY).is_paused
            
            -- we only remove the frame here, if it was previously paused,
            -- as the modification to the is_paused property would be seen in the sitechange event,
            -- resulting in frames not being stored whenever we go from unpaused to paused
            if not self.source_sprite.properties(PLUGIN_KEY).is_paused then
                self:__removeFrame()
            end
        end,

        __syncPauseButton = function(self)
            if self.source_sprite.properties(PLUGIN_KEY).is_paused then
                self.lapse_dialog:modify{
                    id="toggleRecordButton",
                    text = "►"
                }
            else
                self.lapse_dialog:modify{
                    id="toggleRecordButton",
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

        __removeFrame = function(self)
            table.remove(self.__frames, #self.__frames)
                self.lapse_dialog:modify{
                    id = "frameCount",
                    text = "Frames: " .. #self.__frames,
                }
        end,

        cleanup = function(self)
            self:__generateTimelapse():close()
        end,

        __generateTimelapse = function(self)
            
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
            
            for frame_number, frame_image in ipairs(self.__frames) do
                local frame = sprite:newEmptyFrame(frame_number)
                sprite:newCel(sprite.layers[1], frame, frame_image)
            end

            sprite:deleteFrame(#sprite.frames)

            local name, ext = self.source_sprite.filename:match("^(.*)(%..*)$")

            sprite.filename = name .. "-lapse" .. ext
            
            sprite:saveAs(sprite.filename)

            return sprite
        end,


        __timelapseFile = function(self)
            local name, ext = self.source_sprite.filename:match("^(.*)(%..*)$")

            return name .. "-lapse" .. ext
        end,

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
