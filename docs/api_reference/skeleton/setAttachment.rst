===================================
skeleton:setAttachment()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getAttachments`

Overview:
.........
---------

Assigns a specific attachment to a named slot. Pass `nil` as `attachmentName` to
clear the slot’s attachment.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:setAttachment(slotName, attachmentName)

- ``slotName`` *(required)*:
    ``string`` – The name of the slot to assign the attachment to.
- ``attachmentName`` *(required)*:
    ``string`` – The name of the attachment to assign to the slot. Pass `nil` to clear the slot.

Example:
--------
--------

.. code-block:: lua

   -- Equip a sword attachment to the "hand" slot
   hero:setAttachment("hand", "sword")
   
   -- Un-equip the sword
   hero:setAttachment("hand", nil)