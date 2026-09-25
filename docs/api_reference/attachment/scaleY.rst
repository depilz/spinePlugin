=======================================
attachment.scaleY
=======================================

| **Type:** ``number`` (read/write)
| **Attachment Types:** region

The vertical scale factor of the region attachment.

This scale is applied in addition to the image's height and any bone scaling. 
A value of 1.0 means normal scale, 2.0 means double height, 0.5 means half height.

Negative values will flip the attachment vertically.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("shadow")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "region" then
       -- Squash effect
       attachment.scaleX = 1.2
       attachment.scaleY = 0.8
       
       -- Flip vertically
       attachment.scaleY = -1.0
   end

See Also
--------

- :doc:`scaleX` - Horizontal scale
- :doc:`width` - The base width
- :doc:`height` - The base height

