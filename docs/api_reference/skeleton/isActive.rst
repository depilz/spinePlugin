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
   local atlas = spine.loadAtlas("spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   print("Has an animation?", spineboy.isActive) -- false
   spineboy:setAnimation(1, "run", false)
   print("Has an animation?", spineboy.isActive) -- true
   spineboy:clearTrack(1)
   print("Has an animation?", spineboy.isActive) -- false

   local function onEnterFrame(event)
       local now = system.getTimer()
       local dt = now - lastTime
       lastTime = now

       if spineboy.parent then
          spineboy:updateState(dt)
          spineboy:draw()
       end
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)
