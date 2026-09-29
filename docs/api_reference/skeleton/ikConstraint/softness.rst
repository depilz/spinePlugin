===================================
ikConstraint.softness
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

For two bone IK, the target bone's distance from the maximum reach of the bones where rotation begins to 
slow. The bones will not straighten completely until the target is this far out of range.


Example:
--------
--------

.. code-block:: lua

   local ik = hero.ikConstraints[2]
   ik.softness = 5.0