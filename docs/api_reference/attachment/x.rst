=======================================
attachment.x
=======================================

| **Type:** ``number`` (read/write)
| **Attachment types:** region, point

Overview
--------

The X position offset of the attachment relative to its bone, in local space.

For **region** attachments, this is the horizontal offset of the image's center
from the bone position.

For **point** attachments, this is the X coordinate of the point in the bone's
local coordinate system.

For **region** attachments, setting this property updates the attachment's geometry at once: the next
:doc:`../skeleton/draw` shows the change.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("gun")
   local attachment = slot.attachment

   if attachment and attachment.type == "region" then
       -- Get current position
       print("Position:", attachment.x, attachment.y)

       -- Move the attachment 10 pixels to the right
       attachment.x = attachment.x + 10

       -- Center the attachment on the bone
       attachment.x = 0
       attachment.y = 0
   end

   -- For point attachments (spawn points, etc.): offset every point the skeleton shows
   for _, pointSlot in ipairs(skeleton.slots) do
       local point = pointSlot.attachment
       if point and point.type == "point" then
           point.x = 50
           point.y = 0
       end
   end

See also
--------

- :doc:`y` - The Y position offset
- :doc:`rotation` - The rotation angle
- :doc:`computeWorldVertices` - Get world-space positions

