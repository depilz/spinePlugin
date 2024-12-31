===================================
trackEntry.trackEnd
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
--------

The `trackEnd` attribute denotes the end time of the current animation on the specified track, measured 
in **milliseconds**. It represents the point at which the animation is scheduled to conclude, considering 
any delays or mixing durations.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "spell_cast" animation on track 7 with a mix duration of 0.3 seconds
   hero:setAnimation(1, "spell_cast", false)
   hero.tracks[1].trackEnd = 3000  -- Schedule the animation to end at 3 seconds
   
   -- Update the animation state each frame and monitor animation end
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
       
       -- Check if the animation has reached its end time
       if hero.tracks[1].trackTime >= hero.tracks[1].trackEnd then
           print("Spell cast animation has ended.")
           -- Transition to another animation or perform an action
           hero:setAnimation(1, "idle", true)
       end
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)