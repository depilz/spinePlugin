===================================
ikConstraint.target
===================================

| **Type:** :doc:`bone <../bone/index>` | ``nil``
| **See also:** :doc:`index`

Overview:
.........
--------

The :doc:`bone <../bone/index>` object serving as the IK target. The chain of bones controlled
by this IK will try to point towards or reach this target bone.


Example:
--------
--------

.. code-block:: lua

   local armIK = hero.ikConstraints[1]
   local handBone = hero.bones[10]
   armIK.target = handBone