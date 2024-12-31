===================================
ikConstraint.mix
===================================

| **Type:** number (read/write)
| **See also:** :doc:`index`

Overview:
.........
--------

Defines how strongly the IK constraint influences its bones, from `0.0` (no effect)
to `1.0` (fully controlled by IK). Values in between allow partial blending with
other transforms or animations.

Example:
--------
--------

.. code-block:: lua

   local ik = hero.ikConstraints[2]
   ik.mix = 0.5  -- Half IK influence