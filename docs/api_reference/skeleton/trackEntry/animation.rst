===================================
trackEntry.animation
===================================

| **Type:** ``string``
| **See also:** :doc:`index`

Overview:
.........

The `animation` attribute provides the name of the animation currently assigned to the specified track.
This allows you to retrieve or verify which animation is playing on a particular track, facilitating dynamic
animation management and debugging.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "run" animation on track 1 at normal speed
   spineboy:setAnimation(1, "run", true)

   -- Retrieve the name of the current animation on track 1
   local currentAnimation = spineboy.tracks[1].animation
   print("Current Animation on Track 1:", currentAnimation)

   -- Update function using system.getTimer()
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)