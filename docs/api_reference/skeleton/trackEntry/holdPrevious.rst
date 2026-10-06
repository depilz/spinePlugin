===================================
trackEntry.holdPrevious
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`

Overview
--------

The `holdPrevious` attribute is Spine's ``TrackEntry`` flag of the same name, read and written as is. When it is
``true``, the previous entry on the track is applied fully (not faded out) while this entry mixes in over it.

It matters when a higher track mixes between two animations that key the same property a lower track also keys:
without it the value dips briefly toward the lower track's value during the mix; with it the previous animation
keeps covering the lower track until the mix ends. It does not hold any pose after the mix, and a property the new
animation does not key snaps when the mix ends.

Example
-------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Run on track 1, aim on track 2, then mix track 2 to "shoot" without the arm
   -- dropping back to the run's pose during the mix
   spineboy:setAnimation(1, "run", true)
   spineboy:setAnimation(2, "aim", false)
   local shoot = spineboy:addAnimation(2, "shoot", false, 500)
   shoot.holdPrevious = true

   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()

       local entry = spineboy.tracks[2]
       if entry and entry.mixingFrom then
           print("Shoot mixing in, holdPrevious:", entry.holdPrevious)
       end
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)