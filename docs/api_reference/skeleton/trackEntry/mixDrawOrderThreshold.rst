===================================
trackEntry.mixDrawOrderThreshold
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

When the mix percentage (mixTime / mixDuration) is less than the mixDrawOrderThreshold, draw order timelines
are applied while this animation is being mixed out. Defaults to 0, so draw order timelines are not applied
while this animation is being mixed out.

This is a ratio in ``[0..1]``.

Example
-------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "shoot" animation on track 1 with a mix draw order threshold of 0.15
   spineboy:setAnimation(1, "shoot", false)
   spineboy.tracks[1].mixDrawOrderThreshold = 0.15

   -- Transition to the "idle" animation with controlled draw order mixing
   spineboy:addAnimation(1, "idle", true, 400)

   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)