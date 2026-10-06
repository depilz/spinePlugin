===================================
trackEntry.isComplete
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`

Overview
--------

The `isComplete` attribute indicates whether the animation on a specific track has finished
playing. It returns `true` if the animation has completed (i.e., played through once without
looping or has finished its current loop iteration) and ``false`` otherwise.

Example
-------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "shoot" animation on track 1 to play once
   spineboy:setAnimation(1, "shoot", false)

   -- Update the animation state and check completion
   local lastTime = system.getTimer()
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()

       if spineboy.tracks[1].isComplete then
           print("Shoot animation has finished.")
           -- Transition to another animation or perform an action
           spineboy:setAnimation(1, "idle", true)
       end
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)