require 'config'

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

 --- Constructs an SpriteLapse object, responsible for managing (adding and removing frames) the timelapse of the passed source sprite.
 --- fails if the source sprite is another timelapse sprite managed by another SpriteLapse instance.
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
        
        --- constructor helper method, see SpriteLapse function for info
        __init__ = function(self, _source_sprite)

            self.source_sprite = _source_sprite

            -- determine which way to retrieve the lapse_sprite instance, based on the state of the source sprite
            
            if self.source_sprite.properties(PLUGIN_KEY).mode == nil then
                self:__createLapse(self.source_sprite)
                return self
            elseif self.source_sprite.properties(PLUGIN_KEY).mode == "HAS_LAPSE" then
                self:__loadLapse(self.source_sprite)
                return self
            elseif self.source_sprite.properties(PLUGIN_KEY).mode == "IS_LAPSE" then
                print("Cannot create spritelapse for another spritelapse")
            else
                print("Unknown error")
            end

            return nil
        end,
        
        --- Inserts a copy of the passed frame from the source sprite, into a new frame in the lapse_sprite.
        ---@param self any
        ---@param frame any
        --- the frame that should be copied from, if source_sprite is the active sprite, app.frame should be used.
        addFrame = function(self, frame)
            new_frame = self.lapse_sprite:newEmptyFrame(#self.lapse_sprite.frames + 1)

            new_image = Image(self.source_sprite.spec)

            new_image:drawSprite(self.source_sprite, frame.frameNumber)

            new_cell = self.lapse_sprite:newCel(self.lapse_sprite.layers[1], new_frame, new_image)
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

-- app.events:on('sitechange',
-- function()
--     if ActiveLapses[app.sprite] == nil then
--         ActiveLapses[app.sprite] = Lapse()
--     end
-- end)

