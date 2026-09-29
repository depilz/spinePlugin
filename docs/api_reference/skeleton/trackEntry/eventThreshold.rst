===================================
trackEntry.eventThreshold
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........

When the mix percentage (mixTime / mixDuration) is less than the eventThreshold, event timelines are
applied while this animation is being mixed out. Defaults to ``0``, so event timelines are not applied while
this animation is being mixed out.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- eventThreshold is a ratio in [0..1], not milliseconds
   hero:setAnimation(1, "attack", false)
   hero.tracks[1].eventThreshold = 0.2

   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       hero:updateState(dt)
       hero:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)