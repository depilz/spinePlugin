===================================
slot.g
===================================

| **Type:** number (read/write)
| **See also:** :doc:`index`, :doc:`color`, :doc:`../setFillColor`

Overview:
.........
--------

The **green** (G) component of this slot’s color (0–1 range). 
Adjusting `r`, `g`, `b`, or `alpha` individually modifies the overall tint
of the slot’s attachment.

Example:
--------
--------

.. code-block:: lua

   local slot = hero.slots[2]
   slot.g = 1.0  -- max green
   print("Slot green:", slot.g)