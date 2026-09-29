===================================
trackEntry.delay
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
The `delay` attribute specifies the time in **milliseconds** before the animation starts playing on the track,
counted from the start of the previous entry in the track's queue (see :doc:`../addAnimation`).
This allows you to schedule animations to begin after a certain delay, enabling coordinated animation
sequences or timed events.

Example:
--------

.. code-block:: lua

   local lastTime = system.getTimer()

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- Queue the "attack" animation on track 1 with a 1.5-second delay
   hero:addAnimation(1, "attack", false, 1500) -- initial delay of 1500 milliseconds
   print("Cast Spell animation scheduled to start in " .. hero.tracks[1].delay / 1000 .. " seconds")
   hero.tracks[1].delay = 0 -- start the animation immediately

