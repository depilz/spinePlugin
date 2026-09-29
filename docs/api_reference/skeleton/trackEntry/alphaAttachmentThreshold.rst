===================================
trackEntry.alphaAttachmentThreshold
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

When :doc:`alpha` is greater than alphaAttachmentThreshold, attachment timelines are applied. 
Defaults to ``0``, so attachment timelines are always applied.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "fadeOut" animation on track 1 with an alpha attachment threshold of 0.2
   hero:setAnimation(1, "fadeOut", false)
   hero.tracks[1].alphaAttachmentThreshold = 0.2
   
   -- Transition to the "fadeIn" animation with controlled alpha mixing
   hero:addAnimation(1, "fadeIn", true, 300)
   
   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)