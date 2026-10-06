===================================
trackEntry.mixAttachmentThreshold
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

When the mix percentage (mixTime / mixDuration) is less than the mixAttachmentThreshold, attachment timelines
are applied while this animation is being mixed out. Defaults to 0, so attachment timelines are not applied while
this animation is being mixed out.

This is a ratio in ``[0..1]``.

Example
-------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "walk" animation on track 5 with a mix attachment threshold of 0.1
   spineboy:setAnimation(1, "walk", true)
   spineboy.tracks[1].mixAttachmentThreshold = 0.1

   -- Transition to the "run" animation with smooth attachment mixing
   spineboy:addAnimation(1, "run", true, 500)

   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)