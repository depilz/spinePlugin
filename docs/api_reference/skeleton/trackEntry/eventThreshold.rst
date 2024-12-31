===================================
trackEntry.eventThreshold
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
--------

When the mix percentage (mixTime / mixDuration) is less than the eventThreshold, event timelines are 
applied while this animation is being mixed out. Defaults to 0, so event timelines are not applied while 
this animation is being mixed out.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "attack" animation on track 1 with an event threshold of 0.2 seconds
   hero:setAnimation(1, "attack", false)
   hero.tracks[1].eventThreshold = 200  -- 200 milliseconds
   
   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)