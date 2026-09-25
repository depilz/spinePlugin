===================================
slot:setAttachmentFromSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`attachment`, :doc:`../setSkin`

Overview:
.........

Sets this slot's attachment to one from a **specific skin** without changing the skeleton's current skin.

This is particularly useful for:

- **Mix-and-match**: Combining attachments from different skins
- **Customization**: Building custom character appearances
- **Dynamic swapping**: Changing specific parts without affecting the whole skeleton

Syntax:
--------

.. code-block:: lua

   local success = slot:setAttachmentFromSkin(skinName, attachmentName)

Parameters:
-----------

- ``skinName`` *(string, required)*:
    The name of the skin to get the attachment from

- ``attachmentName`` *(string, required)*:
    The name of the attachment within that skin

Returns:
--------

``boolean`` – Returns ``true`` if successful, ``false`` if the skin or attachment was not found. A warning message starting with ``"WARNING: "`` is printed to stderr on failure.

Example:
--------

**Basic Usage:**

.. code-block:: lua

   local slot = hero:getSlot("head")
   
   -- Set head attachment from the "warrior" skin
   slot:setAttachmentFromSkin("warrior", "helmet")

**Mix and Match:**

.. code-block:: lua

   -- Create a character mixing parts from different skins
   local bodySlot = hero:getSlot("body")
   local headSlot = hero:getSlot("head")
   local weaponSlot = hero:getSlot("weapon")
   
   -- Mix attachments from different skins
   bodySlot:setAttachmentFromSkin("knight", "armor")
   headSlot:setAttachmentFromSkin("wizard", "hat")
   weaponSlot:setAttachmentFromSkin("warrior", "sword")

**Dynamic Customization:**

.. code-block:: lua

   -- Let player choose outfit parts
   local function customizeCharacter(outfits)
       for slotName, skinAndAttachment in pairs(outfits) do
           local slot = hero:getSlot(slotName)
           slot:setAttachmentFromSkin(skinAndAttachment.skin, skinAndAttachment.attachment)
       end
   end
   
   customizeCharacter({
       body = { skin = "casual", attachment = "shirt" },
       legs = { skin = "casual", attachment = "jeans" },
       head = { skin = "hats", attachment = "baseball-cap" }
   })

**Error Handling:**

.. code-block:: lua

   local slot = hero:getSlot("weapon")
   
   -- Try to set an attachment and check if it succeeded
   local success = slot:setAttachmentFromSkin("equipment", "legendary-sword")
   
   if not success then
       print("Could not equip legendary sword, using basic sword instead")
       -- Fallback to default weapon
       slot:setAttachmentFromSkin("default", "basic-sword")
   end

**Comparing with slot.attachment:**

.. code-block:: lua

   -- These two are different:
   
   -- Method 1: Uses current/default skin
   slot.attachment = "sword"
   
   -- Method 2: Explicit skin specification
   slot:setAttachmentFromSkin("warrior", "sword")
   
   -- Example showing the difference:
   skeleton:setSkin("mage")
   
   -- This gets "staff" from the mage skin
   slot.attachment = "staff"
   
   -- This gets "sword" specifically from the warrior skin
   slot:setAttachmentFromSkin("warrior", "sword")

Notes:
------

- The skeleton's **current skin remains unchanged** - only this slot is affected
- This is more explicit than using :doc:`attachment` with a string
- Use :doc:`attachment` property for simple cases where current/default skin is appropriate
- Use this method when you need precise control over which skin provides the attachment
- Returns ``false`` and prints a warning instead of throwing an error when the skin or attachment is not found
- Check the return value to handle cases where the skin or attachment might not exist

