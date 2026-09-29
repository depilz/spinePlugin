===================================
skin:findAttachmentsForSlot()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`findNamesForSlot`, :doc:`getAttachment`

Overview:
.........

Returns all attachment objects for a specific slot in the skin. Similar to :doc:`findNamesForSlot`, but returns the full attachment objects instead of just names.

Syntax:
--------

.. code-block:: lua

   local attachments = skin:findAttachmentsForSlot(slot)

Parameters:
-----------

- ``slot`` (string or Slot) – The slot name, or a Slot object of the same skeleton data. A number raises.

Returns:
--------

``table`` – Array of attachment objects for the specified slot.

Example:
--------

Inspect Attachment Details
...........................

.. code-block:: lua

   local skin = skeleton:getSkin()
   local headAttachments = skin:findAttachmentsForSlot("head")
   
   print("Head attachments:")
   for i, attachment in ipairs(headAttachments) do
       print(string.format("  %d. %s (type: %s)", 
           i, attachment.name, attachment.type))
   end

Copy Attachments to New Skin
.............................

.. code-block:: lua

   local sourceSkin = skeleton:getSkin()
   local targetSkin = skeleton:createSkin("filtered")
   
   -- Copy all attachments from specific slots
   local slotsToKeep = {"head", "body", "arms"}
   
   for _, slotName in ipairs(slotsToKeep) do
       local attachments = sourceSkin:findAttachmentsForSlot(slotName)
       
       for _, attachment in ipairs(attachments) do
           targetSkin:setAttachment(slotName, attachment.name, attachment)
       end
   end
   
   skeleton:setSkin(targetSkin)

Filter by Attachment Type
..........................

.. code-block:: lua

   local function getRegionAttachments(slotName)
       local skin = skeleton:getSkin()
       local allAttachments = skin:findAttachmentsForSlot(slotName)
       local regions = {}
       
       for _, attachment in ipairs(allAttachments) do
           if attachment.type == "region" then
               table.insert(regions, attachment)
           end
       end
       
       return regions
   end
   
   local regionAttachments = getRegionAttachments("clothing")

Notes:
--------

- Returns an empty table if no attachments are found for the slot
- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- Each attachment object has properties like ``name`` and ``type``
- More detailed than :doc:`findNamesForSlot` as it returns full attachment objects
- Useful for advanced skin manipulation and inspection
- Raises a Lua error if the slot is not found or has the wrong type

