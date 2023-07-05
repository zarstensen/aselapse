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
        --- instance of the sprite, where the timelapse is actually being stored
        lapse_sprite = nil,
        lapse_dialog = nil,

        --- constructor helper method, see SpriteLapse function for info
        __init__ = function(self, _source_sprite)

            self.source_sprite = _source_sprite


            -- determine which way to retrieve the lapse_sprite instance, based on the state of the source sprite

            if self.source_sprite.properties(PLUGIN_KEY).mode == nil then
                self:__createLapse(self.source_sprite)
            elseif self.source_sprite.properties(PLUGIN_KEY).mode == "HAS_LAPSE" then
                self:__loadLapse(self.source_sprite)
            elseif self.source_sprite.properties(PLUGIN_KEY).mode == "IS_LAPSE" then
                print("Cannot create spritelapse for another spritelapse")
            else
                print("Unknown error")
            end

            if self.lapse_sprite == nil then
                return nil
            end

            self.lapse_dialog = Dialog { title="Timelapse" }
            :label
            {
                id = "frameCount",
                text = "Frames: " .. self:__frameCount(),
            }
            :button
            {
                id="generateTimelapse",
                text="Generate",
                onclick = function()
                    self:generateTimelapse()
                end
            }
            :button
            {
                id="toggleRecordButton",
                text="►",
                onclick = function()
                    self:togglePause()

                    if self.__is_paused then
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
            }

            self.__sprite_event_key = self.source_sprite.events:on('change',
                function(ev)
                    if self.__is_paused then
                        return
                    end

                    self:storeFrame(app.frame)
                end)

            self.__modifications = 0

            return self
        end,

        focus = function(self, focused)
            if focused then
                self.lapse_dialog:show{ wait = false }
            else
                self.lapse_dialog:close()
            end
        end,

        togglePause = function(self)
            self.__is_paused = not self.__is_paused
        end,

        --- Inserts a copy of the passed frame from the source sprite, into a new frame in the lapse_sprite.
        ---@param self any
        ---@param frame any
        --- the frame that should be copied from, if source_sprite is the active sprite, app.frame should be used.
        storeFrame = function(self, frame)
            -- local new_frame = self.lapse_sprite:newEmptyFrame(#self.lapse_sprite.frames + 1)

            local new_image = Image(self.source_sprite.spec)

            new_image:drawSprite(self.source_sprite, frame.frameNumber)

            
            local timelapse_folder = self:__timelapseFolder()

            -- new_image:saveAs(timelapse_folder .. app.fs.fileTitle(self.source_sprite.filename) .. "-lapse-" .. #app.fs.listFiles(timelapse_folder) + 1 .. "-1.aseprite")

            self.lapse_dialog:modify{
                id = "frameCount",
                text = "Frames: " .. self:__frameCount(),
            }
        end,

        generateTimelapse = function(self)
            local files = app.fs.listFiles(self:__timelapseFolder())

            local frames = { }

            local lapse_sprite = Sprite(self.source_sprite.filename)

            for _, file in ipairs(files) do
                frames[file] = tonumber(file:match(".*%-lapse%-(%d+)%.aseprite"))
            end

            table.sort(files, function(left, right)
                return frames[left] < frames[right]
            end)

            for _, file in ipairs(files) do
                local sprite_frame = Sprite{ fromFile = file }
                print(file)
            end

        end,

        __sprite_event_key = nil,
        __is_paused = true,
        __timelapse_file_match = ".+%-lapse%-(%d+)%-(%d+).aseprite",

        __frameCount = function(self)
            local frame_count = 0

            for _, file in ipairs(app.fs.listFiles(self:__timelapseFolder())) do
                local _, file_frame_count = file:match(self.__timelapse_file_match)

                frame_count = frame_count + tonumber(file_frame_count)
            end

            return frame_count
        end,

        __timelapseFolder = function(self)
            local root_dir = app.fs.filePath(self.source_sprite.filename)
            local sprite_name = app.fs.fileTitle(self.source_sprite.filename)
            local timelapse_folder = root_dir .. '/' .. sprite_name .. "-timelapse/"

            return timelapse_folder
        end,

        --- Private
        --- constructs a new sprite that will store the timelapse of the source sprite.
        --- also marks the source and time lapse sprite, so later loads can determine whether to load or create a new timelapse sprite.
        ---@param self any
        __createLapse = function(self)
            -- print("CREATING A NEW SPRITELAPSE")

            -- timelapse sprites have the same named as the source sprite except prefixed with -lapse.
            -- in order to do this, the file name and extension must be separated, using the following match. 

            local name, ext = self.source_sprite.filename:match("^(.*)(%..*)$")

            self.lapse_sprite = Sprite(self.source_sprite)

            self.lapse_sprite.filename = name .. "-lapse" .. ext

            -- to simplify storing later on, all frames will be flattened in the timelapse.

            self.lapse_sprite:flatten()

            self.lapse_sprite.properties(PLUGIN_KEY).mode = "IS_LAPSE"

            self.source_sprite.properties(PLUGIN_KEY).mode = "HAS_LAPSE"
            self.source_sprite.properties(PLUGIN_KEY).lapse_file = self.lapse_sprite.filename

            self.lapse_sprite:saveAs(self.lapse_sprite.filename)
            self.source_sprite:saveAs(self.source_sprite.filename)

            app.sprite = self.source_sprite
        end,


        __loadLapse = function(self)
            -- print("LOADING ALREADY EXISTING LAPSE")

            -- the file name of the timelapse sprite should have been stored earlier in the lapse_file property in the source sprite.

            local file_name = self.source_sprite.properties(PLUGIN_KEY).lapse_file

            -- first check if the timelapse sprite is already open

            for i, sprite in ipairs(app.sprites) do
                if sprite.filename == file_name then
                    self.lapse_sprite = sprite
                    return
                end
            end

            -- else open the file from disk

            local tmp_spite = app.sprite

            self.lapse_sprite = Sprite{ fromFile = self.source_sprite.properties(PLUGIN_KEY).lapse_file }

            -- whenever a sprite is created, it is also focused, so immediatly swap the focus back to the previous sprite.

            app.sprite = tmp_spite
        end,
    }

    return spritelapse:__init__(source_sprite)
end
