===================================
skeleton.slots
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`, :doc:`slot/index`

Overview:
.........
--------

An array of :doc:`slot/index` objects, each representing the attachments (images, meshes, etc.) assigned to bones in this skeleton.

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- Print out all slot names
   for i, slot in ipairs(hero.slots) do
       print("Slot:", i, "Name:", slot.name)
   end