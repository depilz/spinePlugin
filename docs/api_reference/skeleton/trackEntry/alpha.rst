===================================
trackEntry.alpha
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`/naming`

Overview:
.........

Values < 1 mix this animation with the skeleton's current pose (usually the pose resulting from lower tracks).
Defaults to 1, which overwrites the skeleton's current pose with this animation. Typically track 0 is used to
completely pose the skeleton, then alpha is used on higher tracks. It doesn't make sense to use alpha on track
0 if the skeleton pose is from the last frame render.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the "idle" animation on track 1 with a 50% mix
   spineboy:setAnimation(1, "idle", true)
   spineboy.tracks[1].alpha = 0.5

   -- Transition to the "walk" animation with a 75% mix
   spineboy:addAnimation(1, "walk", true, 1000)

   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time

       spineboy:updateState(dt)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)