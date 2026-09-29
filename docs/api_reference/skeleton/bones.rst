===================================
skeleton.bones
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`, :doc:`bone/index`, :doc:`/naming`

Overview:
.........

An array of :doc:`bone/index` objects, each controlling the transform (position, rotation, scale) of a skeleton’s structure.

Example:
--------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- Iterate bones and print their names
   for i, bone in ipairs(hero.bones) do
       print("Bone:", i, "Name:", bone.name)
   end