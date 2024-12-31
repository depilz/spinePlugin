===================================
trackEntry.animationEnd
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
--------
The `animationEnd` attribute specifies the end time position of the animation on the specified track, 
measured in **milliseconds**. It represents the point at which the animation is scheduled to conclude, 
considering any delays or mixing durations.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "slide" animation on track 1, not looping
   hero:setAnimation(1, "slide", false)
   
   -- Retrieve the animation end time
   local animationEndTime = hero.tracks[1].animationEnd
   print("Slide Animation End Time (ms):", animationEndTime)
   
   -- Update the animation state each frame and monitor animation end
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
       
       -- Check if the animation has reached its end time
       if hero.tracks[1].trackTime >= hero.tracks[1].animationEnd then
           print("Slide animation has ended.")
           -- Transition to another animation or perform an action
           hero:setAnimation(1, "idle", true)
       end
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)