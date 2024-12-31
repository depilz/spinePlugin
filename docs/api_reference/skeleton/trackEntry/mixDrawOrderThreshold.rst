===================================
trackEntry.mixDrawOrderThreshold
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
--------

When the mix percentage (mixTime / mixDuration) is less than the mixDrawOrderThreshold, draw order timelines 
are applied while this animation is being mixed out. Defaults to 0, so draw order timelines are not applied
while this animation is being mixed out.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "attack" animation on track 1 with a mix draw order threshold of 0.15
   hero:setAnimation(1, "attack", false)
   hero.tracks[1].mixDrawOrderThreshold = 0.15
   
   -- Transition to the "defend" animation with controlled draw order mixing
   hero:addAnimation(1, "defend", true, 400)
   
   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)