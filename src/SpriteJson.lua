json = require 'json'

--- Namespace of methods for modifying a json file holding properties for a specific sprite.
SpriteJson = {

    --- Insert the key value pair [property_name : property_value] into the json file associated with the passed sprite,
    --- and save it to disk.
    ---@param sprite Sprite
    ---@param property_name string
    ---@param property_value any
    setProperty = function(sprite, property_name, property_value)

        if not SpriteJson.__isSaved(sprite) then
            return
        end

        local properties = {}
        
        if app.fs.isFile(SpriteJson.__jsonName(sprite)) then
            properties = SpriteJson.__loadJson(sprite)
        end

        properties[property_name] = property_value

        local json_file = io.open(SpriteJson.__jsonName(sprite), 'w')
        
        json_file:write(json.encode(properties))
        
        json_file:close()

    end,

    --- Retrieve the value associated with the passed key and sprite.
    --- Nil if the key has no value, or does not exist.
    ---@param sprite Sprite
    ---@param property_name string
    ---@return any | nil
    getProperty = function(sprite, property_name)

        if not SpriteJson.__isSaved(sprite) then
            return nil
        end

        if not app.fs.isFile(SpriteJson.__jsonName(sprite)) then
            return nil
        end

        return SpriteJson.__loadJson(sprite)[property_name]
    end,

    --- Modify a property in place, associated with the passed key and sprite.'
    ---@param sprite Sprite
    ---@param property_name string
    ---@param mod_func function
    --- should have the following declaration [function(old_value) return new_value end]
    --- where old_value is the value currently stored at property_name,
    --- and new_value is the value that will replace the old_value.
    modifyProperty = function(sprite, property_name, mod_func)
        SpriteJson.setProperty(sprite, property_name, mod_func(SpriteJson.getProperty(sprite, property_name)))
    end,

    __isSaved = function(sprite)
        return app.fs.isFile(sprite.filename)
    end,

    -- retrieves the json file that will be associated with the passed sprite.
    __jsonName = function(sprite)

        if not SpriteJson.__isSaved(sprite) then
            return nil
        end

        local name = sprite.filename:match("^(.*)%..*$")

        return name .. "-lapse.json"
    end,

    -- load the json file associated with the passed file from disk.
    -- if this fails, an empty table is returned.
    __loadJson = function(sprite) 
        local json_file = io.open(SpriteJson.__jsonName(sprite), 'r')
        local json_data = json_file:read("*all")
        json_file:close()

        local status, result = pcall(json.decode, json_data)

        if status then
            return result
        else
            return { }
        end
    end,
}
