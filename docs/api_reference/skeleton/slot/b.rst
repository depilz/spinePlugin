===================================
slot.b
===================================

| **Type:** number (read/write)
| **See also:** :doc:`index`, :doc:`color`

Overview:
.........
--------

The **blue** (B) component of this slot’s color, in the range [0–1].
Combine with `r`, `g`, and `alpha` to create full RGBA tints.

Example:
--------
--------

.. code-block:: lua

   local slot = hero.slots[2]
   slot.b = 0.2
   print("Slot blue:", slot.b)