=======================================
attachment.rotation
=======================================

| **Type:** ``number`` (read/write)
| **Attachment types:** region, point

Overview
--------

The rotation angle of the attachment in degrees, relative to its bone.

This rotation is applied in the bone's local space before any bone
transformations are applied.

For **region** attachments, setting this property updates the attachment's geometry at once: the next
:doc:`../skeleton/draw` shows the change.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("gun")
   local attachment = slot.attachment

   if attachment and attachment.type == "region" then
       -- Rotate by 45 degrees
       attachment.rotation = 45

       -- Spin the attachment over time
       Runtime:addEventListener("enterFrame", function()
           attachment.rotation = attachment.rotation + 5
       end)
   end

   -- For point attachments: the direction each point faces
   for _, pointSlot in ipairs(skeleton.slots) do
       local point = pointSlot.attachment
       if point and point.type == "point" then
           print(pointSlot.name, "faces", point.rotation, "degrees")
       end
   end

Notes
-----

- Rotation is in degrees (not radians)
- Positive values rotate counter-clockwise
- The total rotation includes this value plus any bone rotation

See also
--------

- :doc:`x` - The X position offset
- :doc:`y` - The Y position offset
- :doc:`scaleX` - Horizontal scale (region only)
- :doc:`scaleY` - Vertical scale (region only)

