=======================================
attachment.width
=======================================

| **Type:** ``number`` (read/write)
| **Attachment Types:** region, mesh

The base width of the attachment in Spine units.

For **region** attachments, this is the width of the rectangular image quad 
before scaling is applied.

For **mesh** attachments, this is used for non-essential mesh data and setup.

Modifying this value will affect the attachment's rendering size.

For **region** attachments, setting this property updates the attachment's geometry at once: the next
:doc:`../skeleton/draw` shows the change.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("banner")
   local attachment = slot.attachment
   
   if attachment and (attachment.type == "region" or attachment.type == "mesh") then
       -- Get current dimensions
       print("Size:", attachment.width, "x", attachment.height)
       
       -- Make it wider
       attachment.width = attachment.width * 1.5
       
       -- Set specific size
       attachment.width = 100
       attachment.height = 50
   end

Notes
-----

- Combines with ``scaleX`` to determine final width: ``finalWidth = width * scaleX``
- Changing width does not automatically update UV coordinates
- Returns ``nil`` for attachment types that don't have width

See Also
--------

- :doc:`height` - The base height
- :doc:`scaleX` - Horizontal scale factor
- :doc:`scaleY` - Vertical scale factor

