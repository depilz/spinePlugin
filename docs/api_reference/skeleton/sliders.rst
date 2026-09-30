===================================
skeleton.sliders
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`, :doc:`slider/index`, :doc:`/naming`

Overview:
.........

A table of the skeleton's :doc:`slider/index` objects, keyed by slider name. A slider is a Spine 4.3 constraint that
plays an animation at a time set from Lua or driven by a bone. A skeleton with no slider reads an empty table.

Each read builds a new table with new Slider objects. Keep the Slider you need instead of reading ``sliders`` every
frame: it stays valid until the skeleton is removed. :doc:`ikConstraints` never lists a slider.

Example:
--------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("diamond.atlas")
   local diamond = spine.create(spine.loadSkeletonData("diamond.skel", atlas))

   -- Print every slider and the animation it plays
   for name, slider in pairs(diamond.sliders) do
       print("Slider:", name, "Animation:", slider.animation)
   end
