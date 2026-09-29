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

.. fragment: syntax line; skin, slot and attachmentName are placeholders
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

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

Get Specific Attachment
.......................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local customSkin = girl:createSkin("custom")
   customSkin:addSkin("full-skins/girl")

   local attachment = customSkin:getAttachment("mouth", "mouth-smile")

   if attachment then
       print("Found attachment:", attachment.name)
   else
       print("Attachment not found")
   end

Copy Specific Attachments
.........................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local sourceSkin = girl:findSkin("full-skins/girl")
   local targetSkin = girl:createSkin("modified")

   -- Copy only specific attachments
   local smile = sourceSkin:getAttachment("mouth", "mouth-smile")
   if smile then
       targetSkin:setAttachment("mouth", "mouth-smile", smile)
   end

Notes:
--------

- Returns ``nil`` if the attachment is not found in the skin
- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- The attachment object returned includes properties like ``name``, ``type``, etc.
- Raises a Lua error if the slot is not found or has the wrong type; only a missing attachment returns ``nil``
