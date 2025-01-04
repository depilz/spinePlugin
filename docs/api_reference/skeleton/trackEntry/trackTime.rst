===================================
trackEntry.trackTime
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

The `trackTime` attribute represents the current time position within the animation on the specified track, 
measured in **milliseconds**. It indicates how far into the animation the playback has progressed.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "dance" animation on track 6, looping
   hero:setAnimation(1, "dance", true)
   
   -- Update the animation state each frame and monitor animation time
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
       
       -- Retrieve the current animation time
       local currentAnimTime = hero.tracks[1].trackTime
       print("Current Animation Time (ms):", currentAnimTime)
       
       -- Example condition based on animation time
       if currentAnimTime >= 5000 then
           print("Dance animation has reached 5 seconds.")
           -- Perform an action or transition to another animation
       end
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)