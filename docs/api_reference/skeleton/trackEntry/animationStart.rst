===================================
trackEntry.animationStart
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
The `animationStart` attribute indicates the starting time position of the animation on the specified
track, measured in **milliseconds**. This value represents where within the animation the playback begins,
allowing you to start the animation from a specific frame or point in time.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "shoot" animation on track 1 to start at 0.3 seconds
   spineboy:setAnimation(1, "shoot", false)
   spineboy.tracks[1].animationStart = 300  -- 0.3 seconds in milliseconds

   -- Update the animation state each frame and monitor animation time
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()

       -- Monitor animation playback
       print("Animation Start Time (ms):", spineboy.tracks[1].animationStart)
       print("Current Track Time (ms):", spineboy.tracks[1].trackTime)
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)