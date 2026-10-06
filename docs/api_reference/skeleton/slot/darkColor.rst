===================================
slot.darkColor
===================================

| **Type:** ``table`` or ``nil`` (read-only)
| **See also:** :doc:`index`, :doc:`color`, :doc:`../fill/effect`

Overview
--------

The slot's dark colour, the second colour of Spine's **tint black** (two-colour tint), as a new table
``{ r = 0–1, g = 0–1, b = 0–1 }``, or ``nil`` when the slot has no dark colour. A slot has one when its
setup data sets a dark colour ("Tint black" in the Spine editor); that is fixed for the slot's lifetime, so a
slot that returns ``nil`` always does.

The values follow the slot's current pose: an animation that keys the dark colour changes them frame by frame.
They are the slot's colour values, not the bytes the renderer draws with (see :doc:`../fill/effect` for how tint black
is drawn and its limits). Each read returns a new table; changing it does not change the slot. The dark colour
is still reported while a skeleton :doc:`fill effect <../fill/effect>` turns tint black off.

``darkColor`` is read-only: the skeleton data and its animations set it. Writing it raises
``SpineSlot: property 'darkColor' is read-only; the skeleton data and its animations set it``.
Reading or writing it on a slot of a removed skeleton raises ``Slot belongs to a removed skeleton``
(see :doc:`/lifecycle`).

Example
-------

.. code-block:: lua

   local dark = spineboy:getSlot("torso").darkColor
   if dark then
      print(("Dark colour RGB: %f, %f, %f"):format(dark.r, dark.g, dark.b))
   else
      print("This slot has no dark colour")
   end
