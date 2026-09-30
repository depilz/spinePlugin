===================================
trackEntry.animationEnd
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
The `animationEnd` attribute specifies the end time position of the animation on the specified track,
measured in **milliseconds**. It represents the point at which the animation is scheduled to conclude,
considering any delays or mixing durations.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "jump" animation on track 1, not looping
   spineboy:setAnimation(1, "jump", false)

   -- Retrieve the animation end time
   local animationEndTime = spineboy.tracks[1].animationEnd
   print("Jump Animation End Time (ms):", animationEndTime)

   -- Update the animation state each frame and monitor animation end
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()

       -- Check if the animation has reached its end time
       if spineboy.tracks[1].trackTime >= spineboy.tracks[1].animationEnd then
           print("Jump animation has ended.")
           -- Transition to another animation or perform an action
           spineboy:setAnimation(1, "idle", true)
       end
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)