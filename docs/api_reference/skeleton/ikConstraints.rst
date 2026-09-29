===================================
skeleton.ikConstraints
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`, :doc:`ikConstraint/index`

Overview:
.........
--------

An array of :doc:`ikConstraint/index` objects, each defining inverse-kinematics relationships in the skeleton (e.g., controlling how limbs bend).

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- Print all IK constraints
   for i, ik in ipairs(hero.ikConstraints) do
       print("IK Constraint:", i, "Name:", ik.name)
   end