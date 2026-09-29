===================================
slot.alpha
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`color`

Overview:
.........

Represents the **alpha** (transparency) channel of the slot’s color (0–1).
`1.0` is fully opaque, while `0.0` is fully transparent.

At ``slot.alpha = 0`` the slot's attachment emits **no geometry** at all (a clipping attachment still
clips). An object injected into the slot with :doc:`../inject` is still placed every drawn frame, with
``isVisible = true``, the same as at any other alpha.

Example:
--------

.. code-block:: lua

   local slot = hero.slots[1]
   slot.alpha = 0.8  -- 80% opacity
   print("Slot alpha:", slot.alpha)