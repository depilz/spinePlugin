===================================
ikConstraint.mix
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`isActive`

Overview:
.........

Defines how strongly the IK constraint influences its bones, from ``0.0`` (no effect)
to ``1.0`` (fully controlled by IK). Values in between allow partial blending with
other transforms or animations.

Set ``mix = 0`` to stop the constraint: it no longer moves its bones until ``mix`` is above ``0`` again.
This is the way to turn an IK constraint off; :doc:`isActive` is read-only.

.. note::

   An animation that keys this constraint's mix sets ``mix`` again every time it is applied, so a value
   written from Lua lasts only until the next update. To keep the constraint stopped, key its mix to ``0``
   in the animation, or stop playing that animation.

Example:
--------

.. code-block:: lua

   local ik = hero.ikConstraints[2]
   ik.mix = 0.5  -- Half IK influence