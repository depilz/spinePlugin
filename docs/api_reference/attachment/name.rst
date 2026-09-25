=======================================
attachment.name
=======================================

| **Type:** ``string`` (read-only)
| **Attachment Types:** All

The name of the attachment as defined in the Spine editor.

This is the identifier used to reference the attachment and is typically 
the same as the image filename (without extension) for region attachments.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("weapon")
   local attachment = slot.attachment
   
   if attachment then
       print("Current attachment:", attachment.name)
       -- Output: "sword" or "shield" etc.
   end

