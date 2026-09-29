===================================
skin:getBones()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getConstraints`

Overview:
.........

Returns the bones associated with this skin. Some skins in Spine can include bone data, particularly for advanced features like linked meshes or skin-specific bones.

Syntax:
--------

.. code-block:: lua

   local bones = skin:getBones()

Returns:
--------

``table`` – Array of bone names (strings) associated with this skin.

Example:
--------

List Skin Bones
...............

.. code-block:: lua

   local skin = skeleton:getSkin()
   local bones = skin:getBones()
   
   if #bones > 0 then
       print("Skin-specific bones:")
       for i, boneName in ipairs(bones) do
           print("  -", boneName)
       end
   else
       print("No skin-specific bones")
   end

Check for Required Bones
.........................

.. code-block:: lua

   local function hasSkinBones(skinName)
       local skin = skeleton:findSkin(skinName)
       
       if skin then
           local bones = skin:getBones()
           return #bones > 0
       end
       
       return false
   end
   
   if hasSkinBones("dragon-wings") then
       print("This skin requires special bone setup")
   end

Combine Skins with Bones
.........................

.. code-block:: lua

   local customSkin = skeleton:createSkin("custom")
   
   -- When adding a skin with bones, they are preserved
   customSkin:addSkin("character-base")
   customSkin:addSkin("special-outfit")  -- Has skin-specific bones
   
   local bones = customSkin:getBones()
   print("Combined skin has", #bones, "bones")

Notes:
--------

- Returns an empty table if the skin has no associated bones
- Skin bones are an advanced Spine feature used for linked meshes and other complex setups
- When using :doc:`addSkin` or :doc:`copySkin`, bone data is preserved
- Most simple skins will return an empty table

