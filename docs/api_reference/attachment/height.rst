=======================================
attachment.height
=======================================

| **Type:** ``number`` (read/write)
| **Attachment types:** region, mesh

Overview
--------

The base height of the attachment in Spine units.

For **region** attachments, this is the height of the rectangular image quad
before scaling is applied.

For **mesh** attachments, this is non-essential data from the Spine editor: the mesh is drawn from its
vertices, so writing ``height`` changes nothing on screen.

For **region** attachments, setting this property updates the attachment's geometry at once: the next
:doc:`../skeleton/draw` shows the change.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("gun")
   local attachment = slot.attachment

   if attachment and attachment.type == "region" then
       -- Make it taller
       attachment.height = attachment.height * 1.2
   end

See also
--------

- :doc:`width` - The base width
- :doc:`scaleY` - Vertical scale factor

