===================================
trackEntry.trackEnd
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

The `trackEnd` attribute denotes the end time of the current animation on the specified track, measured
in **milliseconds**. It represents the point at which the animation is scheduled to conclude, considering
any delays or mixing durations.

Example
-------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "shoot" animation on track 1
   spineboy:setAnimation(1, "shoot", false)
   spineboy.tracks[1].trackEnd = 3000  -- Schedule the animation to end at 3 seconds

   -- Update the animation state each frame and monitor animation end
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()

       -- Check if the animation has reached its end time
       if spineboy.tracks[1].trackTime >= spineboy.tracks[1].trackEnd then
           print("Shoot animation has ended.")
           -- Transition to another animation or perform an action
           spineboy:setAnimation(1, "idle", true)
       end
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)