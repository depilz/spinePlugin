===================================
slot:setAttachmentFromSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`attachment`, :doc:`../setSkin`

Overview:
.........

Sets this slot's attachment to one from a **specific skin** without changing the skeleton's current skin.

This is particularly useful for:

- **Mix-and-match**: Combining attachments from different skins
- **Customization**: Building custom character appearances
- **Dynamic swapping**: Changing specific parts without affecting the whole skeleton

Syntax:
--------

.. fragment: syntax line; slot, skin and attachmentName are placeholders
.. code-block:: lua

   slot:setAttachmentFromSkin(skin, attachmentName)

Parameters:
-----------

- ``skin`` *(string or Skin, required)*:
    The name of the skin to get the attachment from, or a Skin object of the same skeleton data

- ``attachmentName`` *(string, required)*:
    The name of the attachment within that skin

Returns:
--------

``Slot`` – The slot itself, so calls can be chained.

Raises a Lua error, and leaves the slot unchanged, when the skin is not found, has the wrong type or
belongs to different skeleton data, or when the skin has no such attachment for this slot
(``Attachment '<name>' not found in skin '<skin>' for slot '<slot>'``).

Example:
--------

The examples use the mix-and-match example skeleton, whose skins dress the same slots differently.

**Basic Usage:**

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))
   local slot = girl:getSlot("hat")

   -- Set the hat from the "accessories/hat-red-yellow" skin
   slot:setAttachmentFromSkin("accessories/hat-red-yellow", "hat")

**Mix and Match:**

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Create a character mixing parts from different skins
   girl:getSlot("body"):setAttachmentFromSkin("clothes/hoodie-orange", "body")
   girl:getSlot("hat"):setAttachmentFromSkin("accessories/hat-pointy-blue-yellow", "hat")
   girl:getSlot("leg-front"):setAttachmentFromSkin("legs/boots-red", "leg-front")

**Dynamic Customization:**

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Let player choose outfit parts
   local function customizeCharacter(outfits)
       for slotName, skinAndAttachment in pairs(outfits) do
           local slot = girl:getSlot(slotName)
           slot:setAttachmentFromSkin(skinAndAttachment.skin, skinAndAttachment.attachment)
       end
   end

   customizeCharacter({
       body = { skin = "clothes/hoodie-blue-and-scarf", attachment = "body" },
       ["leg-front"] = { skin = "legs/pants-jeans", attachment = "leg-front" },
       hat = { skin = "accessories/hat-red-yellow", attachment = "hat" }
   })

**Error Handling:**

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))
   local slot = girl:getSlot("hat")

   -- Check first, or catch the raise with pcall
   local hats = girl:findSkin("accessories/hat-red-yellow")

   if not (hats and hats:getAttachment("hat", "hat")) then
       print("Could not find the red and yellow hat, using the pointy hat instead")
       slot:setAttachmentFromSkin("accessories/hat-pointy-blue-yellow", "hat")
   else
       slot:setAttachmentFromSkin(hats, "hat")
   end

**Comparing with slot.attachment:**

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))
   local slot = girl:getSlot("hat")

   -- These two are different:
   girl:setSkin("accessories/hat-pointy-blue-yellow")

   -- Method 1: Uses current/default skin, here the pointy blue and yellow hat
   slot.attachment = "hat"

   -- Method 2: Explicit skin specification, here the red and yellow hat; the current skin stays
   slot:setAttachmentFromSkin("accessories/hat-red-yellow", "hat")

Notes:
------

- The skeleton's **current skin remains unchanged** - only this slot is affected
- This is more explicit than using :doc:`attachment` with a string
- Use :doc:`attachment` property for simple cases where current/default skin is appropriate
- Use this method when you need precise control over which skin provides the attachment
- Raises when the skin or the attachment is not found; use :doc:`../findSkin` and :doc:`../../skin/getAttachment` to check first

