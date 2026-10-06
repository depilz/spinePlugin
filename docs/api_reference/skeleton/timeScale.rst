===================================
skeleton.timeScale
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

The **timeScale** attribute globally adjusts the playback speed of all animations for this skeleton.
Setting `timeScale` to `2` doubles the speed, while `0.5` halves it, etc.

If you want to adjust the speed of a single trackEntry or animation, see :doc:`trackEntry/timeScale`.

.. note::

   ``timeScale`` does not scale Spine physics constraints: they keep running at real time. To slow down,
   speed up or pause physics, see :doc:`physicsTimeScale`.

Example
-------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set the skeleton to half-speed
   spineboy.timeScale = 0.5

   local function onEnterFrame(event)
       local now = system.getTimer()
       local dt = now - lastTime
       lastTime = now

       spineboy:updateState(dt)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)