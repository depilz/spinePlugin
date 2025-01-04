===================================
trackEntry.animationStart
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------
The `animationStart` attribute indicates the starting time position of the animation on the specified 
track, measured in **milliseconds**. This value represents where within the animation the playback begins, 
allowing you to start the animation from a specific frame or point in time.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "charge" animation on track 1 to start at 1.5 seconds
   hero:setAnimation(1, "charge", false)
   hero.tracks[1].animationStart = 1500  -- 1.5 seconds in milliseconds
   
   -- Update the animation state each frame and monitor animation time
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
       
       -- Monitor animation playback
       print("Animation Start Time (ms):", hero.tracks[1].animationStart)
       print("Current Track Time (ms):", hero.tracks[1].trackTime)
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)