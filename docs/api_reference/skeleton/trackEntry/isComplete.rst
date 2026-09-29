===================================
trackEntry.isComplete
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

The `isComplete` attribute indicates whether the animation on a specific track has finished 
playing. It returns `true` if the animation has completed (i.e., played through once without 
looping or has finished its current loop iteration) and ``false`` otherwise.

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "attack" animation on track 1 to play once
   hero:setAnimation(1, "attack", false)
   
   -- Update the animation state and check completion
   local lastTime = system.getTimer()
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       hero:updateState(dt)
       hero:draw()
       
       if hero.tracks[1].isComplete then
           print("Attack animation has finished.")
           -- Transition to another animation or perform an action
           hero:setAnimation(1, "idle", true)
       end
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)