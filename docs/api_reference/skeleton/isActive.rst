===================================
skeleton.isActive
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`, :doc:`tracks`

Overview:
.........

The **isActive** attribute is ``true`` when the skeleton has at least one track slot, that is once an
animation (or an empty animation) was set or added on any track. It stays ``true`` after the
animations complete or a single track is cleared with :doc:`clearTrack`, and becomes ``false`` again
only after :doc:`clearTracks`. It does not tell whether an animation is currently playing.

Do not use it to decide whether to call :doc:`updateState` and :doc:`draw`: physics constraints run
even when the skeleton has no track, and skipping those calls freezes them. Call both every frame
while the skeleton is on screen.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   print("Has a track?", hero.isActive) -- false
   hero:setAnimation(1, "run", false)
   print("Has a track?", hero.isActive) -- true

   local function onEnterFrame(event)
       local now = system.getTimer()
       local dt = now - lastTime
       lastTime = now

       if hero.parent then
          hero:updateState(dt)
          hero:draw()
       end
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)
