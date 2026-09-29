===================================
ikConstraint.isActive
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`

Overview:
.........
--------

Indicates whether this IK constraint is currently **active**. If set to ``false``,
the constraint’s effect is disabled, and the bones are left to their usual
animation transforms.

Example:
--------
--------

.. code-block:: lua

   local ik = hero.ikConstraints[1]
   ik.isActive = false  -- Temporarily disable the IK
   ik.isActive = true   -- Re-enable the IK