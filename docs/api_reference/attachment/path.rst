=======================================
attachment.path
=======================================

| **Type:** ``string`` (read-only)
| **Attachment Types:** region, mesh

The file path to the texture or atlas region used by this attachment.

This is typically the path relative to the atlas or the image filename
without extension, as specified in the Spine editor.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("hand1")
   local attachment = slot.attachment

   if attachment and (attachment.type == "region" or attachment.type == "mesh") then
       print("Texture path:", attachment.path)
       -- Output: hand1
   end

Notes
-----

- This is the setup path from the skeleton data
- Read-only - cannot be modified at runtime
- May differ from the attachment name if set explicitly in Spine

See Also
--------

- :doc:`name` - The attachment identifier

