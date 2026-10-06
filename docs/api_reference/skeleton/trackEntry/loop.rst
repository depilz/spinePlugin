===================================
trackEntry.loop
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`, :doc:`/naming`

Overview
--------

The `loop` attribute determines whether the animation on a specific track should repeat indefinitely. Setting
`loop` to `true` will cause the animation to loop continuously, while `false` will play the animation only once.

Example
-------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "shoot" animation on track 2 to play once
   spineboy:setAnimation(1, "shoot", false)

   -- Check if the "shoot" animation is set to loop
   local isLooping = spineboy.tracks[1].loop
   print("Shoot Animation Looping:", isLooping)

   -- Enable looping for the "shoot" animation
   spineboy.tracks[1].loop = true