require 'SpriteLapse'

function DevDialog(dialog)
    local createLapse = function()
        spritelapse = SpriteLapse(app.sprite)

        if spritelapse == nil then
            app.alert("Failed to create timelapse!!!")
        end
    end

    local addFrame = function()
        if spritelapse == nil then
            app.alert("Timelapse does not exist!!!")
        end

        spritelapse:addFrame(app.frame)
    end

    dialog
        :button { id="create_lapse", text="Create Timelapse", onclick=createLapse}
        :button { id="add_frame", text="Add Frame", onclick=addFrame}
end