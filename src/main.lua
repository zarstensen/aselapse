-- make sure the current api version is supported
if app.apiVersion < 23 then
    app.alert("Aselapse requires version 1.3-rc3 or greater to function (api version 23 or greater). To disable this popup, disable the extension.")
    return
end

require 'FocusManager'
require 'SpriteLapse'

-- key used to unsubscribe of the sitechange event
sitechange_key = nil
-- FocusManager instance, for managing all SpriteLapse instances.
focus_manager = nil

--- NOT USED FOR THE MOMENT, JSON FILES ARE USED INSTEAD
---
--- Checks if the passed sprite contains all of the passed properties.
--- If one of the properties are missing, all other properties are set to nil.
--- This makes sure any potentially corrupt sprite, will be reset by the extension, before it is loaded.
---@param sprite Sprite
---@param properties List<string>
function verifySprite(sprite, properties)
    
    if not sprite then
        return
    end 

    local missing_property = false

    for _, property in ipairs(properties) do
        if sprite.properties(PLUGIN_KEY)[property] == nil then
            missing_property = true
            break
        end
    end

    if missing_property then
        for _, property in ipairs(properties) do
            if sprite.properties(PLUGIN_KEY)[property] ~= nil then
                sprite.properties(PLUGIN_KEY)[property] = nil
            end
        end
    end

end

function init(plugin)
    -- initialize a focus manager instance

    focus_manager = FocusManager()

    focus_manager:init()

    -- setup timelapse command

    plugin:newMenuSeparator{
        group="sprite_crop"
    }
    
    plugin:newCommand{
        id="edit_command",
        title="Edit Time Lapse",
        group="sprite_crop",
        onclick = function()

            if not app.fs.isFile(app.sprite.filename) then
                app.alert("Sprite must be saved to disk before a time lapse can be created!")
                return
            end

            if not focus_manager:contains(app.sprite) then
                focus_manager:add(function() return SpriteLapse(app.sprite) end, app.sprite)
            end

            focus_manager:get(app.sprite):openDialog()
            
        end,
        onenabled = function()
            if app.sprite == nil then
                return false
            end

            return not SpriteJson.getProperty(app.sprite, 'has_dialog')
        end,
    }

    -- setup sitechange event, which makes sure any loaded sprite automatically is added to the focus manager, if the sprite has a timelapse

    sitechange_key = app.events:on('sitechange', function()

        if app.sprite and not focus_manager:contains(app.sprite) and SpriteJson.getProperty(app.sprite, 'has_lapse') then
            focus_manager:add(function() return SpriteLapse(app.sprite) end, app.sprite, true)
        end

    end)
    
    -- on load, go through every sprite, and check if they have a time lapse registered, if so, add it to the focus manager instance,
    -- so the user does not have to manually click the "time lapse" command every time the sprite is opened.

    for _, sprite in ipairs(app.sprites) do

        if not focus_manager:contains(sprite) and SpriteJson.getProperty(sprite, 'has_lapse') then
            focus_manager:add(function() return SpriteLapse(sprite) end, sprite)
        end

    end

end

function exit(plugin)
    
    -- cleanup focus manager, unsubscribe from sitechange event, and also generate and save a time lapse for all currently open sprites, that have a timelapse.

    focus_manager:cleanup()

    focus_manager = nil

    app.events:off(sitechange_key)

end
