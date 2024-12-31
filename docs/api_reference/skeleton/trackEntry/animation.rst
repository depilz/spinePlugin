===================================
trackEntry.animation
===================================

| **Type:** string
| **See also:** :doc:`index`

Overview:
.........
--------

The `animation` attribute provides the name of the animation currently assigned to the specified track. 
This allows you to retrieve or verify which animation is playing on a particular track, facilitating dynamic 
animation management and debugging.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "run" animation on track 1 at normal speed
   hero:setAnimation(1, "run", true)
   
   -- Retrieve the name of the current animation on track 1
   local currentAnimation = hero.tracks[1].animation
   print("Current Animation on Track 1:", currentAnimation)
   
   -- Update function using system.getTimer()
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)