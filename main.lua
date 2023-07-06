require 'FocusManager'
require 'SpriteLapse'

sitechange_key = nil
focus_manager = nil

function init(plugin)
    focus_manager = FocusManager()

    focus_manager:init()

    plugin:newMenuSeparator{
        group="sprite_crop"
    }
    
    plugin:newCommand{
        id="edit_command",
        title="Edit Timelapse",
        group="sprite_crop",
        onclick = function()

            if not focus_manager:contains(app.sprite) then
                focus_manager:add(function() return SpriteLapse(app.sprite) end, app.sprite)
            end

            focus_manager:get(app.sprite):openDialog()
            
        end,
        onenabled = function()
            if app.sprite == nil then
                return false
            end

            return not app.sprite.properties(PLUGIN_KEY).has_dialog
        end,
    }

    plugin:newCommand{
        id="close_command",
        title="Close",
        group="sprite_crop",
        onclick=function()
            app.sprite:close()
        end,
    }

    sitechange_key = app.events:on('sitechange', function()

        if app.sprite and not focus_manager:contains(app.sprite) and app.sprite.properties(PLUGIN_KEY).has_lapse then
            focus_manager:add(function() return SpriteLapse(app.sprite) end, app.sprite, true)
        end


        verifySprite(app.sprite, { "has_lapse", "has_dialog", "is_paused" })

    end)
    
    for _, sprite in ipairs(app.sprites) do
        
        verifySprite(sprite, { "has_lapse", "has_dialog", "is_paused" })

        if not focus_manager:contains(sprite) and sprite.properties(PLUGIN_KEY).has_lapse then
            focus_manager:add(function() return SpriteLapse(sprite) end, sprite)
        end


    end

end

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
            sprite.properties(PLUGIN_KEY)[property] = nil
        end
    end

end

function exit(plugin)
    
    local tmp_sprite = app.sprite

    focus_manager:cleanup()
    focus_manager = nil

    -- loop over all sprites whilst saving and closing any timelapse files
    for _, sprite in ipairs(app.sprites) do
        if sprite.properties(PLUGIN_KEY).mode == "IS_LAPSE" then
            sprite:saveAs(sprite.filename)
            sprite:close()
        end
    end

    app.sprite = tmp_sprite

    app.events:off(sitechange_key)

end
