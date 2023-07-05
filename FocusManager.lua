require 'config'

--- Class responsible for sending focus and unfocus events to managed classes, whenever the focused sprite changes.
--- The manager instance will invoke a focused method, where a boolean will be passed, representing whether the sprite has been focused or not. 
---@return FocusManager | nil
--- nil if construction failed
function FocusManager()

    local dialog_manager = {

        --- Associates the passed object with the passed sprite.
        --- This means obj:focus(state) will have state = true, when the associated sprite is the active sprite,
        --- and false otherwise.  
        ---@param obj Table
        ---@param sprite Sprite
        ---@return Table
        --- obj
        add = function(self, obj, sprite)

            self.__objects[self.__curr_id] = obj
            sprite.properties(PLUGIN_KEY).object_id = self.__curr_id
            self.__curr_id = self.__curr_id + 1

            self:__updateDialog()

            return obj
        end,


        --- Removes the object associated with the passed sprite.
        ---@param sprite Sprite
        remove = function(self, sprite)
            self.__objects[sprite.properties(PLUGIN_KEY).object_id] = nil
            sprite.properties(PLUGIN_KEY).object_id = nil

            self.__active_object = nil
        end,

        init = function(self)

            self.__sitechange_key = app.events:on('sitechange', function()
                self:__updateDialog()
            end)
        end,

        --- Cleanup method, should be called right before assigning.
        --- We need a separate cleanup method that is called as soon as the extension is being disabled,
        --- instead of waitning for garbage collection to finalize this object,
        --- as this otherwise results in this instance recieving sitechange events,
        --- when it is not fit to handle them, thus resulting in runtime errors. 
        cleanup = function(self)
            app.events:off(self.__sitechange_key)

            for _, dialog in pairs(self.__objects) do
                dialog:focus(false)
            end

            for _, sprite in ipairs(app.sprites) do
                sprite.properties(PLUGIN_KEY).object_id = nil
            end

        end,

        -- list of the currently open dialogs
        __objects = {},
        -- the id the next opened dialog should be assigned,
        __curr_id = 1,
        -- key to use when unsubscribing from sitechange event.
        __sitechange_key = nil,

        --- Notifies all the objects managed by the FocusManager instance, that have had their focused change.
        --- Should be called whenever the active sprite changes.
        __updateDialog = function(self)
            -- objects focus state change depending on the active sprite,
            -- so if the sprite has not changed, we do nothing.
            if app.sprite == self.__active_sprite then
                return
            end

            self.__active_sprite = app.sprite

            -- now we notify the currently focused object

            if self.__active_object ~= nil then
                self.__active_object:focus(false)
            end

            self.__active_object = nil

            -- check if we have an object for the current sprite, if so we notify it.

            if self.__active_sprite == nil then
                return
            end

            if self.__active_sprite.properties(PLUGIN_KEY).object_id == nil then
                self.__active_sprite = nil
                return
            end
            
            self.__active_object = self.__objects[self.__active_sprite.properties(PLUGIN_KEY).object_id]

            if self.__active_object == nil then
                self.__active_sprite.properties(PLUGIN_KEY).object_id = nil
                return
            end

            self.__active_object:focus(true)
        end
    }

    return dialog_manager
end