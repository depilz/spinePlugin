===================================
trackEntry.holdPrevious
===================================

| **Type:** boolean
| **See also:** :doc:`index`

Overview:
.........
--------

The `holdPrevious` attribute determines whether the current animation should hold the pose of the 
previous animation when it completes. Setting `holdPrevious` to `true` ensures that the skeleton 
retains the final pose of the previous animation after the current animation finishes.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   
   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set the "jump" animation on track 3 to hold the previous pose after completion
   hero:setAnimation(3, "jump", false)
   hero.tracks[3].holdPrevious = true
   
   -- Update the animation state each frame
   local function onEnterFrame(event)
       local time = system.getTimer()
       local dt = time - lastTime
       lastTime = time
   
       hero:updateState(dt)
       hero:draw()
       
       if hero.tracks[3].isComplete then
           print("Jump animation completed and pose held.")
           -- The skeleton remains in the jump's final pose
       end
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)