===================================
skeleton.isActive
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

The **isActive** attribute indicates whether any animation tracks are currently playing on this
skeleton. If at least one track is active, `isActive` returns `true`. Otherwise, it returns `false`.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   hero:setAnimation(1, "run", false)

   local function onEnterFrame(event)
       local now = system.getTimer()
       local dt = now - lastTime
       lastTime = now

       -- Check if the skeleton is playing any animations
       print("Is the skeleton active?", hero.isActive)
       if hero.isActive then
          hero:updateState(dt)
          hero:draw()
       end

   end

   Runtime:addEventListener("enterFrame", onEnterFrame)