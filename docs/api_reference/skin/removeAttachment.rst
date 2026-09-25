===================================
skin:removeAttachment()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setAttachment`, :doc:`getAttachment`

Overview:
.........

Removes an attachment from the skin by slot index (or name) and attachment name.

Syntax:
--------

.. code-block:: lua

   local success = skin:removeAttachment(slotIndex, attachmentName)
   -- or using slot name
   local success = skin:removeAttachment(slotName, attachmentName)

Parameters:
-----------

- ``slotIndex`` (number) or ``slotName`` (string) – The zero-based slot index or slot name
- ``attachmentName`` (string) – The name of the attachment to remove

Returns:
--------

``boolean`` – Returns ``true`` if successful, ``false`` if the slot was not found or invalid. A warning message starting with ``"WARNING: "`` is printed to stderr on failure.

Example:
--------

Remove Specific Attachments
............................

.. code-block:: lua

   local customSkin = skeleton:createSkin("custom")
   customSkin:copySkin("default")
   
   -- Remove an unwanted attachment by slot index
   customSkin:removeAttachment(3, "weapon")
   
   -- Remove by slot name
   customSkin:removeAttachment("weapon-slot", "sword")
   
   skeleton:setSkin(customSkin)

Clean Up Skin
.............

.. code-block:: lua

   local skin = skeleton:createSkin("cleaned")
   skin:addSkin("full-character")
   
   -- Remove all accessories
   local accessories = {"hat", "glasses", "necklace"}
   for _, accessory in ipairs(accessories) do
       skin:removeAttachment("accessory-slot", accessory)
   end

Notes:
--------

- Both slot index (number) and slot name (string) are supported
- Does nothing if the attachment is not found
- To add back an attachment, use :doc:`setAttachment`
- Returns ``false`` and prints a warning instead of throwing an error when the slot is not found
- Check the return value to handle cases where the slot might not exist

