===================================
skin:getAttachments()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview:
.........

Returns a table of all attachments in the skin. Each entry contains the slot index and attachment name. Useful for debugging or inspecting skin contents.

Syntax:
--------

.. code-block:: lua

   local attachments = skin:getAttachments()

Returns:
--------

``table`` – Array of attachment info tables, each containing:

- ``slotIndex`` (number) – The zero-based slot index for this attachment
- ``name`` (string) – The skin lookup key (placeholder name), not necessarily the object name
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
           print(string.format("  [%d] Slot %d: %s", 
               i, attachment.slotIndex, attachment.name))
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

