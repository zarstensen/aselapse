require 'DevDialog'
require 'DialogManager'

function init(plugin)
    dialog_manager = DialogManager()

    plugin:newMenuSeparator{
        group="sprite_crop"
    }
    
    plugin:newCommand{
        id="edit_command",
        title="Edit Timelapse",
        group="sprite_crop",
        onclick = function()
            local dev_dialog = dialog_manager:createDialog("Aselapse Dev Window", app.sprite)
            
            DevDialog(dev_dialog)

            dialog_manager:showDialog(app.sprite)
        end,
        onenabled = function()
            if app.sprite == nil then
                return false
            end

            return app.sprite.properties("zarstensen/spritelapse").mode ~= "IS_LAPSE"
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

    dialog_manager:cleanup()
    dialog_manager = nil

    print(#app.sprites)

    -- loop over all sprites whilst saving and closing any timelapse files
    for _, sprite in ipairs(app.sprites) do
        print(sprite.filename)
        print(sprite.properties("zarstensen/spritelapse").mode)
        if sprite.properties("zarstensen/spritelapse").mode == "IS_LAPSE" then
            sprite:saveAs(sprite.filename)
            sprite:close()
        end
    end

    app.sprite = tmp_sprite

end

-- local dev_dialog = DevDialog()

-- dev_dialog:show{ wait = false }
