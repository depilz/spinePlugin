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

.. fragment: syntax line; slot is a placeholder
.. code-block:: lua

   local attachmentObject = slot.attachment  -- Returns Attachment userdata or nil

**Writing:**

.. fragment: syntax lines; slot, "attachmentName" and attachmentObject are placeholders
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

   local slot = spineboy:getSlot("gun")
   local attachment = slot.attachment

   if attachment then
       print("Current attachment:", attachment.name)
       print("Attachment type:", attachment.type)
   else
       print("No attachment set")
   end

**Setting by Name:**

.. code-block:: lua

   local slot = spineboy:getSlot("gun")

   -- Clear it
   slot.attachment = nil

   -- Set it again from the current/default skin
   slot.attachment = "gun"

**Setting by Object:**

.. code-block:: lua

   -- Get an attachment from a specific skin
   local skin = skeleton:findSkin("default")
   local attachment = skin:getAttachment("gun", "gun")

   -- Set it directly
   skeleton:findSlot("gun").attachment = attachment

**Using with Different Skins:**

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))
   local slot = girl:findSlot("hat")

   -- Set the skeleton's skin first
   girl:setSkin("accessories/hat-red-yellow")

   -- Now slot.attachment uses that skin
   slot.attachment = "hat"  -- the red and yellow hat

   -- Change skin: the same key now finds another hat
   girl:setSkin("accessories/hat-pointy-blue-yellow")
   slot.attachment = "hat"  -- the pointy blue and yellow hat

Notes:
------

- When setting by **string name** and the attachment is not found, it raises ``Attachment not found: <name>``
- An attachment object of other skeleton data raises ``Attachment belongs to different skeleton data``
- The slot's attachment will not be changed if the lookup fails
- For more explicit skin control, use :doc:`setAttachmentFromSkin`
- Reading ``slot.attachment`` returns the actual Attachment object, not a string