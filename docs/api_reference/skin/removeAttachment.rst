===================================
skin:removeAttachment()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setAttachment`, :doc:`getAttachment`

Overview:
.........

Removes an attachment from the skin by slot and attachment name.

Syntax:
--------

.. code-block:: lua

   skin:removeAttachment(slot, attachmentName)

Parameters:
-----------

- ``slot`` (string or Slot) – The slot name, or a Slot object of the same skeleton data. A number raises.
- ``attachmentName`` (string) – The name of the attachment to remove

Returns:
--------

``Skin`` – The skin itself, so calls can be chained.

Raises a Lua error, and changes nothing, when this skin is a data skin (read-only), or when the
slot is not found or has the wrong type.

Example:
--------

Remove Specific Attachments
............................

.. code-block:: lua

   local customSkin = skeleton:createSkin("custom")
   customSkin:copySkin("default")
   
   -- Remove an unwanted attachment
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

- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- Does nothing if the attachment is not found
- To add back an attachment, use :doc:`setAttachment`
- Raises on a data skin: data skins are read-only (see :doc:`index`)
- To remove every entry at once, use :doc:`clear`

