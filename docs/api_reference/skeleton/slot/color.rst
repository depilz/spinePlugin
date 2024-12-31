===================================
slot.color
===================================

| **Type:** table (read-only)
| **See also:** :doc:`index`, :doc:`r`, :doc:`g`, :doc:`b`, :doc:`alpha`

Overview:
.........
--------

A convenience table containing the RGBA components of this slot’s color:
``{ r = 0–1, g = 0–1, b = 0–1, a = 0–1 }``. Changing values in this table
*will not* apply them to the slot; instead, set the fields
(`slot.r`, `slot.g`, etc.) individually.

Example:
--------
--------

.. code-block:: lua

   local c = hero.slots[2].color
   print(("Slot color RGBA: %f, %f, %f, %f"):format(c.r, c.g, c.b, c.a))