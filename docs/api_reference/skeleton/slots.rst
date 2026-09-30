===================================
skeleton.slots
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`, :doc:`slot/index`, :doc:`/naming`

Overview:
.........

An array of :doc:`slot/index` objects, each representing the attachments (images, meshes, etc.) assigned to bones in this skeleton.

Example:
--------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Print out all slot names
   for i, slot in ipairs(spineboy.slots) do
       print("Slot:", i, "Name:", slot.name)
   end