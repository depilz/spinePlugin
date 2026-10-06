===================================
skin:getAttachments()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview
--------

Returns a table of all attachments in the skin. Each entry contains the slot name, the lookup key and the attachment. Useful for debugging or inspecting skin contents.

Syntax
------

.. fragment: syntax line; skin is a placeholder
.. code-block:: lua

   local attachments = skin:getAttachments()

Return value
------------

``table`` – Array of attachment info tables, each containing:

- ``slotName`` (string) – The name of the slot this entry is for
- ``placeholder`` (string) – The skin lookup key (placeholder name), not necessarily the object name
- ``attachment`` (Attachment) – The attachment object

Example
-------

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

List All Attachments
~~~~~~~~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   girl:setSkin("full-skins/girl")
   local currentSkin = girl:getSkin()

   if currentSkin then
       local attachments = currentSkin:getAttachments()
       print("Attachments in", currentSkin.name .. ":")

       for i, attachment in ipairs(attachments) do
           print(string.format("  [%d] Slot %s: %s",
               i, attachment.slotName, attachment.placeholder))
       end
   end

Compare Skins
~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local skin1 = girl:createSkin("compare1")
   skin1:addSkin("full-skins/girl")

   local skin2 = girl:createSkin("compare2")
   skin2:addSkin("full-skins/boy")

   print("Skin 1 attachments:", #skin1:getAttachments())
   print("Skin 2 attachments:", #skin2:getAttachments())
