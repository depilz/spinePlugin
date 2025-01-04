===================================
trackEntry.reverse
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`

Overview:
.........
--------

The `reverse` attribute determines whether the animation should play in reverse. Setting `reverse` to `true` 
will play the animation backward from its end to its start, creating a mirrored effect of the original animation.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "swing" animation on track 4 to play in reverse
   hero:setAnimation(1, "swing", false)
   hero.tracks[1].reverse = true
   
   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)