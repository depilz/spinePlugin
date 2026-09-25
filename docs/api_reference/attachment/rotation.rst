=======================================
attachment.rotation
=======================================

| **Type:** ``number`` (read/write)
| **Attachment Types:** region, point

The rotation angle of the attachment in degrees, relative to its bone.

This rotation is applied in the bone's local space before any bone 
transformations are applied.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("propeller")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "region" then
       -- Rotate by 45 degrees
       attachment.rotation = 45
       
       -- Spin the attachment over time
       Runtime:addEventListener("enterFrame", function()
           attachment.rotation = attachment.rotation + 5
       end)
   end
   
   -- For point attachments
   local pointSlot = skeleton:findSlot("muzzle")
   local point = pointSlot.attachment
   
   if point and point.type == "point" then
       -- Point rotation affects spawned effects
       print("Muzzle facing:", point.rotation, "degrees")
   end

Notes
-----

- Rotation is in degrees (not radians)
- Positive values rotate counter-clockwise
- The total rotation includes this value plus any bone rotation

See Also
--------

- :doc:`x` - The X position offset
- :doc:`y` - The Y position offset
- :doc:`scaleX` - Horizontal scale (region only)
- :doc:`scaleY` - Vertical scale (region only)

