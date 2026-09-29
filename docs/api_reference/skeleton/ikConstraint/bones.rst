===================================
ikConstraint.bones
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

An array of :doc:`bone <../bone/index>` objects controlled by this IK constraint.

Example:
--------
--------

.. code-block:: lua

   local ik = hero.ikConstraints[2]
   for i, bone in ipairs(ik.bones) do
       print("Bone in IK chain:", bone.name)
   end