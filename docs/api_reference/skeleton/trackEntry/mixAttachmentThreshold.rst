===================================
trackEntry.mixAttachmentThreshold
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
--------

When the mix percentage (mixTime / mixDuration) is less than the mixAttachmentThreshold, attachment timelines 
are applied while this animation is being mixed out. Defaults to 0, so attachment timelines are not applied while 
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
   
   -- Set the "walk" animation on track 5 with a mix attachment threshold of 0.1
   hero:setAnimation(1, "walk", true)
   hero.tracks[1].mixAttachmentThreshold = 0.1
   
   -- Transition to the "run" animation with smooth attachment mixing
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