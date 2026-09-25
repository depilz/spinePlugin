===================================
skin:getAttachment()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setAttachment`, :doc:`removeAttachment`

Overview:
.........

Returns a specific attachment from the skin by slot index (or name) and attachment name.

Syntax:
--------

.. code-block:: lua

   local attachment = skin:getAttachment(slotIndex, attachmentName)
   -- or using slot name
   local attachment = skin:getAttachment(slotName, attachmentName)

Parameters:
-----------

- ``slotIndex`` (number) or ``slotName`` (string) – The zero-based slot index or slot name to query
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
   
   -- Get attachment by slot index
   local attachment = customSkin:getAttachment(0, "head")
   
   -- Get attachment by slot name  
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
- Both slot index (number) and slot name (string) are supported
- The attachment object returned includes properties like ``name``, ``type``, etc.
- Prints a warning message starting with ``"WARNING: "`` to stderr if the slot is not found or invalid

