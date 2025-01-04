===================================
trackEntry.shortestRotation
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`

Overview:
.........
--------

If `true`, mixing rotation between tracks always uses the shortest rotation direction. If 
the rotation is animated, the shortest rotation direction may change during the mix. If 
`false`, the shortest rotation direction is remembered when the mix starts and the same 
direction is used for the rest of the mix. Defaults to `false`.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "turn" animation on track 2 to use the shortest rotation
   hero:setAnimation(2, "turn", false)
   hero.tracks[2].shortestRotation = true
   
   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)