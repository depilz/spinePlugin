===================================
slot.r
===================================

| **Type:** number (read/write)
| **See also:** :doc:`index`, :doc:`color`, :doc:`../setFillColor`

Overview:
.........
--------

The **red** (R) component of this slot’s color (0–1 range). 
Adjusting `r`, `g`, `b`, or `alpha` individually modifies the overall tint
of the slot’s attachment.

Example:
--------
--------

.. code-block:: lua

   local slot = hero.slots[2]
   slot.r = 1.0  -- max red
   print("Slot red:", slot.r)