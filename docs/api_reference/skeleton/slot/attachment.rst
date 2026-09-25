===================================
slot.attachment
===================================

| **Type:** ``string`` | ``Attachment`` | ``nil``
| **See also:** :doc:`index`, :doc:`setAttachmentFromSkin`, :doc:`../../attachment/index`

String assignment uses the skin lookup key and searches current skin then default
skin, exactly like :doc:`../setAttachment`. A missing key raises a Lua error and
leaves the slot unchanged. Direct object assignment bypasses lookup and requires
an object from the same skeleton data. Use ``nil`` to clear the slot.
See :doc:`/attachments-and-skins` for animation overrides and ownership.

Overview:
.........

Gets or sets the current attachment displayed by this slot. Can be set using:

- **String**: Attachment name from the skeleton's **current or default skin**
- **Attachment object**: Direct attachment reference (from any skin)
- **nil**: Clears the attachment

When reading, returns an Attachment object or ``nil`` if no attachment is set.

Syntax:
--------

**Reading:**

.. code-block:: lua

   local attachmentObject = slot.attachment  -- Returns Attachment userdata or nil

**Writing:**

.. code-block:: lua

   -- Set by name (uses current or default skin)
   slot.attachment = "attachmentName"
   
   -- Set by Attachment object
   slot.attachment = attachmentObject
   
   -- Clear attachment
   slot.attachment = nil

Behavior:
---------

When setting by **string name**, the attachment is looked up in this order:

1. The skeleton's **current skin** (if set via ``skeleton:setSkin()``)
2. The skeleton's **default skin** (fallback)

If you need to set an attachment from a **specific skin** without changing the skeleton's current skin, use :doc:`setAttachmentFromSkin`.

Example:
--------

**Reading Attachment:**

.. code-block:: lua

   local slot = hero:getSlot("weapon")
   local attachment = slot.attachment
   
   if attachment then
       print("Current attachment:", attachment.name)
       print("Attachment type:", attachment.type)
   else
       print("No attachment set")
   end

**Setting by Name:**

.. code-block:: lua

   local slot = hero:getSlot("weapon")
   
   -- Set from current/default skin
   slot.attachment = "sword"
   
   -- Later, change to another attachment
   slot.attachment = "axe"
   
   -- Clear it
   slot.attachment = nil

**Setting by Object:**

.. code-block:: lua

   -- Get an attachment from a specific skin
   local skin = skeleton:getSkin()
   local attachment = skin:getAttachment("weapon", "sword")
   
   -- Set it directly
   slot.attachment = attachment

**Using with Different Skins:**

.. code-block:: lua

   -- Set the skeleton's skin first
   skeleton:setSkin("warrior")
   
   -- Now slot.attachment uses the warrior skin
   slot.attachment = "helmet"  -- Gets "helmet" from warrior skin
   
   -- Change skin
   skeleton:setSkin("mage")
   slot.attachment = "hat"  -- Gets "hat" from mage skin

Notes:
------

- When setting by **string name** and the attachment or skin is not found, a warning message starting with ``"WARNING: "`` is printed to stderr, but no error is thrown
- The slot's attachment will not be changed if the lookup fails
- For more explicit skin control, use :doc:`setAttachmentFromSkin` which returns a boolean success value
- Reading ``slot.attachment`` returns the actual Attachment object, not a string