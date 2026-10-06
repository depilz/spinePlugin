===================================
skin:findNamesForSlot()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`findAttachmentsForSlot`

Overview
--------

Returns all attachment names available for a specific slot in the skin. Useful for discovering what attachments exist for a particular slot.

Syntax
------

.. fragment: syntax line; skin and slot are placeholders
.. code-block:: lua

   local names = skin:findNamesForSlot(slot)

Parameters
----------

- ``slot`` *(required)*:
    ``string`` or ``Slot`` – The slot name, or a Slot object of the same skeleton data. A number raises.
    A Slot of a removed skeleton raises.

Return value
------------

``table`` – Array of lookup keys / skin placeholder names (strings), which may differ from attachment object names for the specified slot.

Example
-------

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

List Available Options
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local skin = girl:findSkin("full-skins/girl")

   local mouthOptions = skin:findNamesForSlot("mouth")

   print("Available mouths:")
   for _, name in ipairs(mouthOptions) do
       print("  -", name)
   end

Create Selection UI
~~~~~~~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   girl:setSkin("full-skins/girl")

   local function createAttachmentSelector(slotName)
       local currentSkin = girl:getSkin()
       local options = currentSkin:findNamesForSlot(slotName)

       -- Create UI buttons for each option
       for i, attachmentName in ipairs(options) do
           local button = display.newText({
               text = attachmentName,
               y = i * 40
           })

           button:addEventListener("tap", function()
               girl:setAttachment(slotName, attachmentName)
           end)
       end
   end

   createAttachmentSelector("mouth")

Random Customization
~~~~~~~~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   girl:setSkin("full-skins/girl")

   local function randomizeSlot(slotName)
       local skin = girl:getSkin()
       local options = skin:findNamesForSlot(slotName)

       if #options > 0 then
           local randomIndex = math.random(1, #options)
           girl:setAttachment(slotName, options[randomIndex])
       end
   end

   -- Randomize character appearance
   randomizeSlot("mouth")
   randomizeSlot("hair-back")
   randomizeSlot("eye-front-iris")

Notes
-----

- Returns an empty table if no attachments are found for the slot
- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- Useful for implementing character customization interfaces
- To get the actual attachment objects (not just names), use :doc:`findAttachmentsForSlot`
- Raises a Lua error if the slot is not found or has the wrong type
