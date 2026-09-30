===================================
ikConstraint.name
===================================

| **Type:** ``string`` (read-only)
| **See also:** :doc:`index`

Overview:
.........

The **name** of this IK constraint, as defined in Spine.

Example:
--------

.. code-block:: lua

   local ik = spineboy.ikConstraints[1]
   print("IK Constraint name:", ik.name)