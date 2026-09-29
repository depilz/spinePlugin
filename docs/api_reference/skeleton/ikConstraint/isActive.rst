===================================
ikConstraint.isActive
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`, :doc:`mix`, :doc:`/naming`

Overview:
.........

Indicates whether this IK constraint is currently **active**. Spine decides this itself: a constraint is
inactive when it is skin-required and the current skin does not include it, or when its target bone is
inactive. The value changes when the skin changes.

.. only:: spine43

   .. note::

      On the 4.3 line (``plugin.spine43``), earlier builds always read ``true`` here, because of a spine-cpp 4.3
      runtime issue that the plugin now patches: ``Skeleton::updateCache`` set a different active flag than the one
      ``isActive()`` reads. ``isActive`` now reads ``false`` for an inactive constraint on both lines, and the
      constraint's animation timelines no longer change it while it is inactive.

``isActive`` is read-only. Writing it raises the error
``IK constraint isActive is read-only; set mix = 0 to stop it``. To stop the constraint, set its
:doc:`mix` to ``0``; set it back to a value above ``0`` to restart it.

Example:
--------

.. code-block:: lua

   local ik = hero.ikConstraints[1]
   print("IK active:", ik.isActive)

   ik.mix = 0  -- Stop the IK
   ik.mix = 1  -- Restart it
