===================================
skin:findNamesForSlot()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`findAttachmentsForSlot`

Overview:
.........

Returns all attachment names available for a specific slot in the skin. Useful for discovering what attachments exist for a particular slot.

Syntax:
--------

.. code-block:: lua

   local names = skin:findNamesForSlot(slot)

Parameters:
-----------

- ``slot`` (string or Slot) – The slot name, or a Slot object of the same skeleton data. A number raises.

Returns:
--------

``table`` – Array of lookup keys / skin placeholder names (strings), which may differ from attachment object names for the specified slot.

Example:
--------

List Available Options
.......................

.. code-block:: lua

   local skin = skeleton:getSkin()
   
   local weaponOptions = skin:findNamesForSlot("weapon-slot")
   
   print("Available weapons:")
   for _, name in ipairs(weaponOptions) do
       print("  -", name)
   end

Create Selection UI
...................

.. code-block:: lua

   local function createAttachmentSelector(slotName)
       local currentSkin = skeleton:getSkin()
       local options = currentSkin:findNamesForSlot(slotName)
       
       -- Create UI buttons for each option
       for i, attachmentName in ipairs(options) do
           local button = display.newText({
               text = attachmentName,
               y = i * 40
           })
           
           button:addEventListener("tap", function()
               skeleton:setAttachment(slotName, attachmentName)
           end)
       end
   end
   
   createAttachmentSelector("head")

Random Customization
....................

.. code-block:: lua

   local function randomizeSlot(slotName)
       local skin = skeleton:getSkin()
       local options = skin:findNamesForSlot(slotName)
       
       if #options > 0 then
           local randomIndex = math.random(1, #options)
           skeleton:setAttachment(slotName, options[randomIndex])
       end
   end
   
   -- Randomize character appearance
   randomizeSlot("head")
   randomizeSlot("body")
   randomizeSlot("legs")

Notes:
--------

- Returns an empty table if no attachments are found for the slot
- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- Useful for implementing character customization interfaces
- To get the actual attachment objects (not just names), use :doc:`findAttachmentsForSlot`
- Raises a Lua error if the slot is not found or has the wrong type

