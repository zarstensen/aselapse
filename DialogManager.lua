require 'config'

--- Class responsible for managing a single dialog type, across multiple sprites.
--- Does this by allowing a dialog to be tied with a specific sprite, when opened.
--- When opened, the dialog will only be shown, when the sprite it has been tied to, is the active sprite.
---@return DialogManager | nil
--- nil if construction failed
function DialogManager()

    local dialog_manager = {
        ---constructor helper, see DialogManager for info.
        __init__ = function(self)

            self.__sitechange_key = app.events:on('sitechange', function()
                self:__updateDialog()
            end)

            return self
        end,

        --- Constructs a dialog and associates the dialog instance with the passed sprite.
        --- After construction, further widgets can be added, before calling showDialog.
        ---@param title string
        ---@param sprite Sprite
        ---@return Dialog
        createDialog = function(self, title, sprite)

            local dialog = Dialog{
                title = title,
                onclose = function()

                    -- if the user has closed the dialog, it should be removed from the dialog manager,
                    -- as it should not be open again, when changing to the associated sprite

                    if not self.__active_sprite.properties(PLUGIN_KEY).manager_closed then
                        -- do not close the dialog when removing it, as this will invoke this very function again,
                        --- and inevitably lead to a stack overflow exception
                        self:removeDialog(sprite, false)
                    end

                    self.__active_sprite.properties(PLUGIN_KEY).manager_closed = nil
                end}

            self.__dialogs[self.__curr_id] = dialog
            self.__active_dialog = dialog
            self.__active_sprite = sprite
            sprite.properties(PLUGIN_KEY).dialog_id = self.__curr_id
            self.__curr_id = self.__curr_id + 1

            return dialog
        end,

        --- Shows the dialog associated with the passed sprite.
        --- createDialog must have been called with the passed sprite, before this is called.
        ---@param sprite Sprite
        showDialog = function(self, sprite)
            self.__active_sprite = sprite
            self.__active_dialog = self.__dialogs[self.__active_sprite.properties(PLUGIN_KEY).dialog_id]

            self.__active_dialog:show{ wait = false }
        end,

        --- Removes the dialog associated with the passed sprite.
        --- Optionally closes the dialog (optional to prevent infinite recursion).
        ---@param sprite Sprite
        ---@param close boolean
        removeDialog = function(self, sprite, close)

            if close then
                self.__dialogs[sprite.properties(PLUGIN_KEY).dialog_id]:close()
            end

            self.__dialogs[sprite.properties(PLUGIN_KEY).dialog_id] = nil
            sprite.properties(PLUGIN_KEY).dialog_id = nil

            self.__active_dialog = nil
        end,

        --- Cleanup method, should be called right before assigning.
        --- We need a separate cleanup method that is called as soon as the extension is being disabled,
        --- instead of waitning for garbage collection to finalize this object,
        --- as this otherwise results in this instance recieving sitechange events,
        --- when it is not fit to handle them, thus resulting in runtime errors. 
        cleanup = function(self)
            app.events:off(self.__sitechange_key)

            for _, dialog in pairs(self.__dialogs) do
                dialog:close()
            end

        end,

        -- list of the currently open dialogs
        __dialogs = {},
        -- the id the next opened dialog should be assigned,
        __curr_id = 1,
        -- key to use when unsubscribing from sitechange event.
        __sitechange_key = nil,

        --- Updates the current state of all the dialogs managed by the DialogManager instance.
        --- Meaning this will open the dialog, if any, that is associated with the current sprite,
        --- and close all others.
        --- Should be called whenever the active sprite changes.
        __updateDialog = function(self)
            -- dialouges change depending on the active sprite,
            -- so if the sprite has not changed, we do nothing.
            if app.sprite == self.__active_sprite then
                return
            end

            self.__active_sprite = app.sprite

            -- now we close the currently open dialog

            if self.__active_dialog ~= nil then
                self.__active_sprite.properties(PLUGIN_KEY).manager_closed = true
                self.__active_dialog:close()
            end

            self.__active_dialog = nil

            -- check if we have a dialog for the current window, if so we show it.

            if self.__active_sprite == nil then
                return
            end

            if self.__active_sprite.properties(PLUGIN_KEY).dialog_id == nil then
                return
            end

            self.__active_dialog = self.__dialogs[self.__active_sprite.properties(PLUGIN_KEY).dialog_id]
            self.__active_dialog:show{ wait = false }
        end
    }

    return dialog_manager:__init__()
end