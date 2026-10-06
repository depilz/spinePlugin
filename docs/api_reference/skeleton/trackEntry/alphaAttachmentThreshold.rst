===================================
trackEntry.alphaAttachmentThreshold
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

When :doc:`alpha` is greater than alphaAttachmentThreshold, attachment timelines are applied.
Defaults to ``0``, so attachment timelines are always applied.

Example
-------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "jump" animation on track 1 with an alpha attachment threshold of 0.2
   spineboy:setAnimation(1, "jump", false)
   spineboy.tracks[1].alphaAttachmentThreshold = 0.2

   -- Transition to the "idle" animation with controlled alpha mixing
   spineboy:addAnimation(1, "idle", true, 300)

   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)