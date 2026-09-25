===================================
skeleton:registerSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`createSkin`, :doc:`setSkin`, :doc:`../skin/index`

Overview:
.........

Registers a custom Skin object with the SkeletonData, making it available by name for all skeleton instances created from the same data. Once registered, the skin can be applied using ``skeleton:setSkin(skinName)`` with just the skin's name string.

This is useful when you want to reuse a custom skin combination across multiple skeleton instances or save custom character configurations.

Syntax:
--------

.. code-block:: lua

   skeleton:registerSkin(skinObject)
    
- ``skinObject`` *(required)*:
    ``Skin`` – The custom Skin object to register, created with :doc:`createSkin`.

Example:
--------

Register and Reuse
..................

.. code-block:: lua

   -- Create and configure a custom skin
   local customSkin = skeleton:createSkin("playerAvatar")
   customSkin:addSkin("base")
   customSkin:addSkin("warrior")
   customSkin:addSkin("legendary")
   
   -- Register it for reuse
   skeleton:registerSkin(customSkin)
   
   -- Now it can be used by name
   skeleton:setSkin("playerAvatar")
   
   -- Other skeleton instances can also use it
   local skeleton2 = Spine.create(parent, skeletonData, x, y)
   skeleton2:setSkin("playerAvatar")

Save Player Customization
..........................

.. code-block:: lua

   -- Function to apply player's saved customization
   local function applyPlayerCustomization(skeleton, savedSkins)
       local customSkin = skeleton:createSkin("player_custom")
       
       -- Add each saved skin part
       for _, skinName in ipairs(savedSkins) do
           customSkin:addSkin(skinName)
       end
       
       -- Register so it persists
       skeleton:registerSkin(customSkin)
       skeleton:setSkin(customSkin)
       
       return customSkin
   end
   
   -- Load player's saved customization
   local playerSkins = {"base", "armor_knight", "helm_royal", "weapon_sword"}
   applyPlayerCustomization(skeleton, playerSkins)

Notes:
--------

- Registered skins are shared across all skeleton instances from the same SkeletonData
- Re-registering the same object is a no-op; a different skin with the same name raises a Lua error
- The skin must come from the same skeleton data
- Once registered, the skin's memory is managed by the SkeletonData
- Registration transfers ownership - the custom skin should not be manually deleted

