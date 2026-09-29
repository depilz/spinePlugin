===================================
skin:getAttachments()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview:
.........

Returns a table of all attachments in the skin. Each entry contains the slot name, the lookup key and the attachment. Useful for debugging or inspecting skin contents.

Syntax:
--------

.. code-block:: lua

   local attachments = skin:getAttachments()

Returns:
--------

``table`` – Array of attachment info tables, each containing:

- ``slotName`` (string) – The name of the slot this entry is for
- ``placeholder`` (string) – The skin lookup key (placeholder name), not necessarily the object name
- ``attachment`` (Attachment) – The attachment object

Example:
--------

List All Attachments
....................

.. code-block:: lua

   local currentSkin = skeleton:getSkin()
   
   if currentSkin then
       local attachments = currentSkin:getAttachments()
       print("Attachments in", currentSkin.name .. ":")
       
       for i, attachment in ipairs(attachments) do
           print(string.format("  [%d] Slot %s: %s", 
               i, attachment.slotName, attachment.placeholder))
       end
   end

Compare Skins
.............

.. code-block:: lua

   local skin1 = skeleton:createSkin("compare1")
   skin1:addSkin("soldier")
   
   local skin2 = skeleton:createSkin("compare2")
   skin2:addSkin("warrior")
   
   print("Skin 1 attachments:", #skin1:getAttachments())
   print("Skin 2 attachments:", #skin2:getAttachments())

