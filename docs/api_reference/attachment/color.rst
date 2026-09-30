=======================================
attachment.color
=======================================

| **Type:** ``table`` (read/write)
| **Attachment Types:** region, mesh, point, path, boundingbox, clipping
| **See also:** :doc:`index`, :doc:`r`, :doc:`g`, :doc:`b`, :doc:`a`, :doc:`/naming`

The color tint applied to the attachment. The table contains four components:

- ``r`` - Red channel (0.0 to 1.0)
- ``g`` - Green channel (0.0 to 1.0)
- ``b`` - Blue channel (0.0 to 1.0)
- ``a`` - Alpha/opacity (0.0 to 1.0)

The attachment's color is multiplied with the skeleton's and the slot's colors to produce the final
rendered color (see Notes). Setting a table with only some of the components changes only those components. :doc:`r`, :doc:`g`, :doc:`b` and
:doc:`a` read and write the same colour one component at a time.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("gun")
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

- Every attachment type has a color; only region and mesh attachments are drawn, so only their color shows
- Values are stored as given, not clamped: keep each component between 0.0 and 1.0
- The final rendered color is the product of the skeleton's fill color (:doc:`../skeleton/setFillColor`),
  the Spine slot color that animations key, :doc:`../skeleton/slot/color` and ``attachment.color``

