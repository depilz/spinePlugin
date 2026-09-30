===================================
trackEntry.reverse
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`

Overview:
.........

The `reverse` attribute determines whether the animation should play in reverse. Setting `reverse` to `true`
will play the animation backward from its end to its start, creating a mirrored effect of the original animation.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "shoot" animation on track 1 to play in reverse
   spineboy:setAnimation(1, "shoot", false)
   spineboy.tracks[1].reverse = true

   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)