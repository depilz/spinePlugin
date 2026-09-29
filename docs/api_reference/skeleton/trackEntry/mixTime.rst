===================================
trackEntry.mixTime
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........

The `mixTime` attribute is the time in **milliseconds** this entry has been mixing in from the previous entry:
``0`` when the mix starts, growing each :doc:`../updateState` until it reaches :doc:`mixDuration`, the length of the
mix. ``mixTime / mixDuration`` is how far the transition has progressed. Writing ``mixTime`` moves the mix to that
point.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- Walk, then transition to "run" after 500 milliseconds with a 300-millisecond mix
   hero:setAnimation(1, "walk", true)
   local run = hero:addAnimation(1, "run", true, 500)
   run.mixDuration = 300

   -- Update the animation state each frame and report the mix progress
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       hero:updateState(dt)
       hero:draw()

       local entry = hero.tracks[1]
       if entry.mixingFrom then
           print(("Mix %d%% done"):format(100 * entry.mixTime / entry.mixDuration))
       end
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)