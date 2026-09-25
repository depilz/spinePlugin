===================================
skin:addSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`copySkin`, :doc:`../skeleton/createSkin`

Overview:
.........

Adds all attachments from another skin to this skin. Attachments are shared by reference (not copied), making this operation fast and memory-efficient.

If an attachment with the same slot and name already exists in this skin, it will be replaced by the attachment from the other skin.

Syntax:
--------

.. code-block:: lua

   local success = skin:addSkin(skinNameOrObject)
    
- ``skinNameOrObject`` *(required)*:
    ``string`` or ``Skin`` – Either the name of an existing skin or a Skin object.

Returns:
--------

``boolean`` – Returns ``true`` if successful, ``false`` if the skin was not found or invalid. A warning message starting with ``"WARNING: "`` is printed to stderr on failure.

Example:
--------

Combine Multiple Skins
.......................

.. code-block:: lua

   -- Create a custom skin
   local avatar = skeleton:createSkin("myCharacter")
   
   -- Add attachments from multiple skins
   avatar:addSkin("base")       -- Base body
   avatar:addSkin("warrior")    -- Warrior equipment
   avatar:addSkin("cape")       -- Cape accessory
   
   -- Apply the combined skin
   skeleton:setSkin(avatar)

Layer Skins
...........

.. code-block:: lua

   -- Build up a character by layering skins
   local character = skeleton:createSkin("hero")
   
   -- Add base, then layer customization on top
   character:addSkin("body_type_1")
   character:addSkin("head_type_2")
   character:addSkin("armor_knight")
   character:addSkin("weapon_sword")
   
   skeleton:setSkin(character)

Notes:
--------

- Attachments are shared, not copied (references only)
- Later additions overwrite duplicate slot/attachment combinations
- Very fast operation - suitable for runtime character customization
- For independent copies, use :doc:`copySkin` instead
- Returns ``false`` and prints a warning instead of throwing an error when the skin is not found
- Check the return value to handle cases where the skin might not exist

