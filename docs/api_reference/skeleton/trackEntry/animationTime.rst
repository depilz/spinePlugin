===================================
trackEntry.animationTime
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

The `animationTime` attribute indicates the current playback time of the animation on the specified track,
measured in **milliseconds**. It represents how far into the animation the playback has progressed.

Example
-------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "idle" animation on track 1, looping
   spineboy:setAnimation(1, "idle", true)

   -- Update the animation state each frame and monitor animation time
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()

       -- Retrieve the current animation time
       local currentAnimTime = spineboy.tracks[1].animationTime
       print("Current Animation Time (ms):", currentAnimTime)
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)