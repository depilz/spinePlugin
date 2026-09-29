===================================
skin:getAttachment()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setAttachment`, :doc:`removeAttachment`

Overview:
.........

Returns a specific attachment from the skin by slot and attachment name.

Syntax:
--------

.. code-block:: lua

   local attachment = skin:getAttachment(slot, attachmentName)

Parameters:
-----------

- ``slot`` (string or Slot) – The slot name, or a Slot object of the same skeleton data. A number raises.
- ``attachmentName`` (string) – The name of the attachment to retrieve

Returns:
--------

``attachment`` – The attachment object, or ``nil`` if not found.

Example:
--------

Get Specific Attachment
.......................

.. code-block:: lua

   local customSkin = skeleton:createSkin("custom")
   customSkin:addSkin("default")
   
   local attachment = customSkin:getAttachment("head-slot", "head")
   
   if attachment then
       print("Found attachment:", attachment.name)
   else
       print("Attachment not found")
   end

Copy Specific Attachments
..........................

.. code-block:: lua

   local sourceSkin = skeleton:getSkin()
   local targetSkin = skeleton:createSkin("modified")
   
   -- Copy only specific attachments
   local headAttachment = sourceSkin:getAttachment("head", "default-head")
   if headAttachment then
       targetSkin:setAttachment("head", "default-head", headAttachment)
   end

Notes:
--------

- Returns ``nil`` if the attachment is not found in the skin
- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- The attachment object returned includes properties like ``name``, ``type``, etc.
- Raises a Lua error if the slot is not found or has the wrong type; only a missing attachment returns ``nil``

