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

.. fragment: syntax line; skin and slot are placeholders
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

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

Inspect Attachment Details
...........................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local skin = girl:findSkin("full-skins/girl")
   local mouthAttachments = skin:findAttachmentsForSlot("mouth")

   print("Mouth attachments:")
   for i, attachment in ipairs(mouthAttachments) do
       print(string.format("  %d. %s (type: %s)",
           i, attachment.name, attachment.type))
   end

Copy Attachments to New Skin
.............................

This method returns attachment objects without their lookup keys, and a key (the skin placeholder)
can differ from ``attachment.name``: in ``full-skins/girl`` the key ``mouth-smile`` maps to the
object ``girl/mouth-smile``. To copy entries under their keys, use the entry records of
:doc:`getAttachments`, which carry ``slotName`` and ``placeholder``:

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local sourceSkin = girl:findSkin("full-skins/girl")
   local targetSkin = girl:createSkin("filtered")

   -- Copy the entries of specific slots, keyed by their placeholder
   local slotsToKeep = { ["base-head"] = true, mouth = true, ["eye-front-iris"] = true }

   for _, entry in ipairs(sourceSkin:getAttachments()) do
       if slotsToKeep[entry.slotName] then
           targetSkin:setAttachment(entry.slotName, entry.placeholder, entry.attachment)
       end
   end

   girl:setSkin(targetSkin)
   print(girl:getSlot("mouth").attachment.name)  -- the entries kept their keys

Filter by Attachment Type
..........................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local function getRegionAttachments(skinName, slotName)
       local allAttachments = girl:findSkin(skinName):findAttachmentsForSlot(slotName)
       local regions = {}

       for _, attachment in ipairs(allAttachments) do
           if attachment.type == "region" then
               table.insert(regions, attachment)
           end
       end

       return regions
   end

   local regionAttachments = getRegionAttachments("full-skins/girl", "mouth")
   print(#regionAttachments)

Notes:
--------

- Returns an empty table if no attachments are found for the slot
- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- Each attachment object has properties like ``name`` and ``type``
- More detailed than :doc:`findNamesForSlot` as it returns full attachment objects
- Useful for advanced skin manipulation and inspection
- Raises a Lua error if the slot is not found or has the wrong type
