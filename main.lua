require 'DevDialog'
require 'FocusManager'
require 'AselapseDialog'

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

            focus_manager:add(SpriteLapse(app.sprite), app.sprite)
            
        end,
        onenabled = function()
            if app.sprite == nil then
                return false
            end

            return app.sprite.properties(PLUGIN_KEY).mode ~= "IS_LAPSE"
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

end

-- local dev_dialog = DevDialog()

-- dev_dialog:show{ wait = false }
