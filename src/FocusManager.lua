require 'config'
require 'SpriteJson'

--- Class responsible for sending focus and unfocus events to managed classes, whenever the focused sprite changes.
--- The manager instance will invoke a focused method, where a boolean will be passed, representing whether the sprite has been focused or not. 
---
--- Make sure to call FocusManager:cleanup(), whenever the object is no longer needed.
---@return FocusManager | nil
--- nil if construction failed
function FocusManager()
    
    local dialog_manager = {
        init = function(self)
            
            -- the sitechange event is used to check, whether the current sprite has changed
            
            self.__sitechange_key = app.events:on('sitechange', function()
                self:__updateFocus()
            end)

        end,
        
        --- Cleanup method, should be called right before assigning this instance to nil.
        --- We need a separate cleanup method that is called as soon as the extension is being disabled,
        --- instead of waitning for garbage collection to finalize this object,
        --- as this otherwise results in this instance recieving sitechange events,
        --- when it is not fit to handle them, thus resulting in runtime errors. 
        cleanup = function(self)

            -- unsubscribe to sitechange events

            app.events:off(self.__sitechange_key)
            
            -- call cleanup on any managed objects that define a cleanup method,
            -- also make sure to call focus(false), in order to make all managed objects hide any potential ui elements.

            for _, dialog in pairs(self.__objects) do
                dialog:focus(false)
        
                if dialog.cleanup then
                    dialog:cleanup()
                end
            end

            for _, sprite in ipairs(app.sprites) do
                SpriteJson.setProperty(sprite, 'object_id', nil)
            end
        
        end,
        
        --- Associates the result of the passed object factory, with the passed sprite.
        --- This means obj:focus(focused) will have focused = true, when the associated sprite is the active sprite,
        --- and false otherwise.  
        --- When the FocusManager's cleanup method is called, it will also call a cleanup [obj:cleanup()] method on all of its stored objects,
        --- if they have defined such a method.
        ---
        --- A factory is used here instead of an object instance, as the construction of the object, might need to check FocusManager:contains,
        --- which will return, if contains is called on the constructed sprite.
        --- Therefore the FocusManager instance, marks the object as being contained, before the obj_factory is called, ensuring this failure does not occur.
        ---
        ---@param obj_factory Function() -> Table
        ---@param sprite Sprite
        ---@param focus boolean
        --- whether to call focus on the stored object, when it has been registered
        ---@return Table
        --- obj_factory result
        add = function(self, obj_factory, sprite, focus)
            
            -- temporarily unsubscribe from the 'sitechange' event, as the obj_factory might change the active sprite.
            -- if this happens __updateFocus will not call focus properly, as it will attempt to call focus on the placeholder object, instead of the obj_factory result.

            app.events:off(self.__sitechange_key)

            local uuid = tostring(Uuid())

            SpriteJson.setProperty(sprite, 'object_id', uuid)
            -- store a placeholder empty table at the id index, so contains will return true, if it is called during obj_factory.
            self.__objects[uuid] = {}
            self.__objects[uuid] = obj_factory()

            -- resubscribe to the 'sitechange' event, and make sure any focus changed caused by obj_factory is notified to the managed objects, by calling __updateFocus.

            self.__sitechange_key = app.events:on('sitechange', function()
                self:__updateFocus()
            end)

            self:__updateFocus()

            -- if the obj_factory created a sprite, then the focus method would not have been called,
            -- as it would have been called on the placeholder table instead.
            -- Therefore focus is manually invoked here.

            if focus then
                self.__objects[SpriteJson.getProperty(sprite, 'object_id')]:focus(true)
            end

            return self.__objects[SpriteJson.getProperty(sprite, 'object_id')]
        end,


        --- Checks if the passed sprite has an associated object, which is managed by this instance.
        ---@param sprite any
        ---@return boolean
        contains = function(self, sprite)

            -- object_id is set to nil inside the cleanup method, on all active sprites,
            -- however, it is still possible that the user has closed a sprite, which object_id was set.
            -- therefore it is also checked whether there actually exists an object associated with the sprites object_id, if it is not nil.

            if SpriteJson.getProperty(sprite, 'object_id') == nil then
                return false
            else
                return self.__objects[SpriteJson.getProperty(sprite, 'object_id')] ~= nil
            end
        end,

        --- Retrieve the object associated with the given sprite.
        ---@param sprite any
        ---@return Table | nil
        --- nil if the sprite is not managed by the current instance.
        get = function(self, sprite)
            return self.__objects[SpriteJson.getProperty(sprite, 'object_id')]
        end,

        --- Removes the object associated with the passed sprite.
        ---@param sprite Sprite
        remove = function(self, sprite)
            self.__objects[SpriteJson.getProperty(sprite, 'object_id')] = nil
            SpriteJson.setProperty(sprite, 'object_id', nil)

            self.__active_object = nil
        end,



        -- table of the currently managed objects.
        -- each table has a separate unique obj_id
        __objects = {},
        -- key to use when unsubscribing from sitechange event.
        __sitechange_key = nil,

        --- Notifies all the objects managed by the FocusManager instance, that have had their focus changeed.
        --- Should be called whenever the active sprite changes.
        __updateFocus = function(self)

            
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

            if not self:contains(self.__active_sprite) then
                self.__active_sprite = nil
                return
            end
            
            self.__active_object = self:get(self.__active_sprite)

            if self.__active_object.focus then
                self.__active_object:focus(true)
            end
        end
    }

    return dialog_manager
end