=======================================
attachment.color
=======================================

| **Type:** ``table`` (read/write)
| **Attachment Types:** region, mesh, point, path, boundingbox, clipping

The color tint applied to the attachment. The table contains four components:

- ``r`` - Red channel (0.0 to 1.0)
- ``g`` - Green channel (0.0 to 1.0)
- ``b`` - Blue channel (0.0 to 1.0)
- ``a`` - Alpha/opacity (0.0 to 1.0)

The attachment's color is multiplied with the slot's color to produce the final 
rendered color. Setting individual components will modify only those components.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("character")
   local attachment = slot.attachment
   
   if attachment then
       -- Get current color
       local color = attachment.color
       print("Color:", color.r, color.g, color.b, color.a)
       
       -- Set to red tint
       attachment.color = {r=1, g=0, b=0, a=1}
       
       -- Partially transparent
       attachment.color = {r=1, g=1, b=1, a=0.5}
       
       -- Only change red channel
       local currentColor = attachment.color
       currentColor.r = 0.5
       attachment.color = currentColor
   end

Notes
-----

- Returns ``nil`` for attachment types that don't support color
- Color values are clamped to 0.0-1.0 range internally
- The final rendered color is: ``attachment.color * slot.color * skeleton.color``

