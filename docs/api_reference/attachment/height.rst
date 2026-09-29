=======================================
attachment.height
=======================================

| **Type:** ``number`` (read/write)
| **Attachment Types:** region, mesh

The base height of the attachment in Spine units.

For **region** attachments, this is the height of the rectangular image quad 
before scaling is applied.

For **mesh** attachments, this is used for non-essential mesh data and setup.

Modifying this value will affect the attachment's rendering size.

For **region** attachments, setting this property updates the attachment's geometry at once: the next
:doc:`../skeleton/draw` shows the change.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("shield")
   local attachment = slot.attachment
   
   if attachment and (attachment.type == "region" or attachment.type == "mesh") then
       -- Make it taller
       attachment.height = attachment.height * 1.2
   end

See Also
--------

- :doc:`width` - The base width
- :doc:`scaleY` - Vertical scale factor

