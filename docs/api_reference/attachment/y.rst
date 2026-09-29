=======================================
attachment.y
=======================================

| **Type:** ``number`` (read/write)
| **Attachment Types:** region, point

The Y position offset of the attachment relative to its bone, in local space.

For **region** attachments, this is the vertical offset of the image's center 
from the bone position.

For **point** attachments, this is the Y coordinate of the point in the bone's 
local coordinate system.

For **region** attachments, setting this property updates the attachment's geometry at once: the next
:doc:`../skeleton/draw` shows the change.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("hat")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "region" then
       -- Move the hat up slightly
       attachment.y = attachment.y + 5
   end

See Also
--------

- :doc:`x` - The X position offset
- :doc:`rotation` - The rotation angle

