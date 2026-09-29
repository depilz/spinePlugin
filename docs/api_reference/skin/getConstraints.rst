===================================
skin:getConstraints()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getBones`

Overview:
.........

Returns the constraints associated with this skin. Some skins in Spine can include constraint data (IK, transform, path, etc.) for skin-specific behavior.

Syntax:
--------

.. fragment: syntax line; skin is a placeholder
.. code-block:: lua

   local constraints = skin:getConstraints()

Returns:
--------

``table`` – Array of constraint names (strings) associated with this skin.

Example:
--------

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

List Skin Constraints
.....................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   girl:setSkin("full-skins/girl")
   local skin = girl:getSkin()
   local constraints = skin:getConstraints()

   if #constraints > 0 then
       print("Skin-specific constraints:")
       for i, constraintName in ipairs(constraints) do
           print("  -", constraintName)
       end
   else
       print("No skin-specific constraints")
   end

Check Constraint Requirements
.............................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local function validateSkinCompatibility(skinName)
       local skin = girl:findSkin(skinName)

       if skin then
           local constraints = skin:getConstraints()

           if #constraints > 0 then
               print("Warning: Skin requires special constraints:")
               for _, name in ipairs(constraints) do
                   print("  -", name)
               end
               return false
           end
       end

       return true
   end

   validateSkinCompatibility("accessories/hat-red-yellow")

Preserve Constraints When Combining
...................................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local customSkin = girl:createSkin("advanced")

   -- Add skins with constraints
   customSkin:addSkin("skin-base")
   customSkin:addSkin("accessories/hat-red-yellow")  -- Has a skin constraint

   local constraints = customSkin:getConstraints()
   print("Combined skin has", #constraints, "constraints")

   -- All constraints are preserved when combining skins
   girl:setSkin(customSkin)

Notes:
--------

- Returns an empty table if the skin has no associated constraints
- Skin constraints are an advanced Spine feature used with skin-specific IK, transforms, etc.
- When using :doc:`addSkin` or :doc:`copySkin`, constraint data is preserved
- Most simple skins will return an empty table
- Constraints can include: IK, transform, path, and physics constraints
