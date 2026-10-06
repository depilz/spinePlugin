=======================================
attachment.scaleX
=======================================

| **Type:** ``number`` (read/write)
| **Attachment types:** region
| **See also:** :doc:`index`, :doc:`xScale`, :doc:`/naming`

Overview
--------

The horizontal scale factor of the region attachment.

This scale is applied in addition to the image's width and any bone scaling.
A value of 1.0 means normal scale, 2.0 means double width, 0.5 means half width.

``attachment.xScale`` is an alias of ``attachment.scaleX``: it reads and writes the same value.

Negative values will flip the attachment horizontally.

For **region** attachments, setting this property updates the attachment's geometry at once: the next
:doc:`../skeleton/draw` shows the change.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("gun")
   local attachment = slot.attachment

   if attachment and attachment.type == "region" then
       -- Get current scale
       print("Scale:", attachment.scaleX, attachment.scaleY)

       -- Make it twice as wide
       attachment.scaleX = 2.0

       -- Flip horizontally
       attachment.scaleX = -1.0

       -- Make it narrower
       attachment.scaleX = 0.5

       -- Uniform scale
       attachment.scaleX = 1.5
       attachment.scaleY = 1.5
   end

Notes
-----

- Default value is 1.0 (normal scale)
- Negative values flip the attachment
- Combined with bone scale: ``finalScale = boneScale * attachmentScale``
- Does not affect collision or physics directly

See also
--------

- :doc:`scaleY` - Vertical scale
- :doc:`width` - The base width
- :doc:`height` - The base height

