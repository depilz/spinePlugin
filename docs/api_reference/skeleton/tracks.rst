===================================
skeleton.tracks
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`, :doc:`trackEntry/index`

Overview:
---------

An array of :doc:`trackEntry/index` objects, each representing an active animation track on the skeleton.


Syntax:
-------

.. code-block:: lua

   -- Accessing a specific animation track
   local track = skeleton.tracks[1]
   
   -- Iterating through all animation tracks
   for i, track in ipairs(skeleton.tracks) do
       print("Track " .. i .. " animation:", track.animation)
   end

- ``tracks`` *(read-only)*:
    ``table`` – An array of :doc:`trackEntry/index` objects representing each active animation track.

Example:
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas)
   local hero = spine.create(skeletonData)
   
   -- Set an initial animation on track 1 (tracks are 1-based in Lua)
   hero:setAnimation(1, "idle", true)
   
   -- Add a walking animation to play after idle
   hero:addAnimation(1, "walk", true, 500) -- delay in milliseconds
   
   -- Iterate through all active tracks and print their animations
   for i, track in ipairs(hero.tracks) do
       print("Track " .. i .. " is playing:", track.animation)
   end
   
   -- Adjust the time scale of the first track
   if hero.tracks[1] then
       hero.tracks[1].timeScale = 1.5  -- 150% speed
   end