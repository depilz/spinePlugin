===================================
trackEntry.loop
===================================

| **Type:** boolean
| **See also:** :doc:`index`

Overview:
.........
--------

The `loop` attribute determines whether the animation on a specific track should repeat indefinitely. Setting 
`loop` to `true` will cause the animation to loop continuously, while `false` will play the animation only once.

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "attack" animation on track 2 to play once
   hero:setAnimation(1, "attack", false)
   
   -- Check if the "attack" animation is set to loop
   local isLooping = hero.tracks[1].loop
   print("Attack Animation Looping:", isLooping)
   
   -- Enable looping for the "attack" animation
   hero.tracks[1].loop = true