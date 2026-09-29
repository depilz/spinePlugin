===================================
skeleton.isActive
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`, :doc:`tracks`, :doc:`/naming`

Overview:
.........

The **isActive** attribute is ``true`` when at least one track has a current entry: an animation (or an empty
animation) that was set, or a queued one that has started. A non-looping animation that has completed stays the
current entry of its track, so ``isActive`` stays ``true``.

It becomes ``false`` when no track has a current entry any more: after :doc:`clearTracks`, after :doc:`clearTrack`
on the last track that had one, or once an empty animation that mixes a track out has ended on every track.

Do not use it to decide whether to call :doc:`updateState` and :doc:`draw`: physics constraints run
even when the skeleton has no track, and skipping those calls freezes them. Call both every frame
while the skeleton is on screen.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   print("Has an animation?", hero.isActive) -- false
   hero:setAnimation(1, "run", false)
   print("Has an animation?", hero.isActive) -- true
   hero:clearTrack(1)
   print("Has an animation?", hero.isActive) -- false

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
