===================================
skeleton.timeScale
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

The **timeScale** attribute globally adjusts the playback speed of all animations for this skeleton.
Setting `timeScale` to `2` doubles the speed, while `0.5` halves it, etc.

If you want to adjust the speed of a single trackEntry or animation, see :doc:`trackEntry/timeScale`.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- Set the skeleton to half-speed
   hero.timeScale = 0.5

   local function onEnterFrame(event)
       local now = system.getTimer()
       local dt = now - lastTime
       lastTime = now

       hero:updateState(dt)
       hero:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)