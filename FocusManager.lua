require 'config'

--- Class responsible for sending focus and unfocus events to managed classes, whenever the focused sprite changes.
--- The manager instance will invoke a focused method, where a boolean will be passed, representing whether the sprite has been focused or not. 
---@return FocusManager | nil
--- nil if construction failed
function FocusManager()
    
    local dialog_manager = {
        init = function(self)
            
            self.__sitechange_key = app.events:on('sitechange', function()
                self:__updateDialog()
            end)

        end,

        --- Associates the passed object with the passed sprite.
        --- This means obj:focus(state) will have state = true, when the associated sprite is the active sprite,
        --- and false otherwise.  
        --- When the FocusManager's cleanup method is called, it will also call a cleanup [obj:cleanup()] method on all of its stored objects,
        --- if they have defined such a method.
        ---@param obj_factory Function() -> Table
        ---@param sprite Sprite
        ---@return Table
        --- obj_factory result
        add = function(self, obj_factory, sprite, focus)

            sprite.properties(PLUGIN_KEY).object_id = self.__curr_id
            -- store a placeholder empty table at the id index, so contains will return true, if it is called during obj_factory.
            self.__objects[self.__curr_id] = {}
            self.__objects[self.__curr_id] = obj_factory()
            self.__curr_id = self.__curr_id + 1

            self:__updateDialog()

            if focus then
                self.__objects[sprite.properties(PLUGIN_KEY).object_id]:focus(true)
            end

            return self.__objects[sprite.properties(PLUGIN_KEY).object_id]
        end,

        contains = function(self, sprite)
            if sprite.properties(PLUGIN_KEY).object_id == nil then
                return false
            else
                return self.__objects[sprite.properties(PLUGIN_KEY).object_id] ~= nil
            end
        end,

        get = function(self, sprite)
            return self.__objects[sprite.properties(PLUGIN_KEY).object_id]
        end,

        --- Removes the object associated with the passed sprite.
        ---@param sprite Sprite
        remove = function(self, sprite)
            self.__objects[sprite.properties(PLUGIN_KEY).object_id] = nil
            sprite.properties(PLUGIN_KEY).object_id = nil

            self.__active_object = nil
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

                if dialog.cleanup then
                    dialog:cleanup()
                end
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

            if self.__active_object ~= nil and self.__active_object.focus then
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
            
            self.__active_object = self:get(self.__active_sprite)

            if self.__active_object == nil then
                self.__active_sprite.properties(PLUGIN_KEY).object_id = nil
                return
            end

            if self.__active_object.focus then
                self.__active_object:focus(true)
            end
        end
    }

    return dialog_manager
end