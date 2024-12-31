===================================
trackEntry.timeScale
===================================

| **Type:** number
| **See also:** :doc:`index`, :doc:`../timeScale`

Overview:
.........
--------

The `timeScale` attribute allows you to adjust the playback speed of a specific animation 
track .i.e. changing `timeScale` affects only the specified track, other tracks or the global 
`timeScale` remain unaffected.

If you want to adjust the speed of all animations for this skeleton, see :doc:`../timeScale`.

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "run" animation on track 1 at normal speed
   hero:setAnimation(1, "run", true)
   
   -- Retrieve the current time scale of track 0
   local currentScale = hero.tracks[1].timeScale
   print("Current Time Scale:", currentScale)
   
   -- Increase the playback speed of track 0 to 150%
   hero.tracks[1].timeScale = 1.5
   
   -- Decrease the playback speed of track 0 to 75%
   hero.tracks[1].timeScale = 0.75