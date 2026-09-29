===================================
trackEntry.mixTime
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

The `mixTime` attribute specifies the duration in **milliseconds** over which the animation mix occurs. This defines how long it takes to blend from the current animation to the next one, ensuring smooth transitions between animations.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "walk" animation on track 1 with a mix time of 500 milliseconds
   hero:setAnimation(1, "walk", true)
   hero.tracks[1].mixTime = 500  -- 500 milliseconds
   
   -- Transition to the "run" animation with a smooth mix over 500 milliseconds
   hero:addAnimation(1, "run", true, 500)
   
   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)