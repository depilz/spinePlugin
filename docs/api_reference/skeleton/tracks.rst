===================================
skeleton.tracks
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`, :doc:`trackEntry/index`, :doc:`getTrackEntry`, :doc:`/naming`

Overview
--------

A plain Lua table with one element per animation track: ``tracks[i]`` is the current :doc:`trackEntry/index` of
track ``i``, or ``false`` when that track has no current entry.

Each read of ``skeleton.tracks`` builds a new table, a snapshot of the tracks at that moment. It covers the tracks
from ``1`` to the highest track used, so ``#skeleton.tracks`` is reliable and ``ipairs`` visits every track. A track
cleared with :doc:`clearTrack` reads ``false`` and keeps its place; after :doc:`clearTracks` the table is empty.

Changing the table does not change the skeleton. The entries in it are the same objects :doc:`getTrackEntry`
returns: writing to them changes the animation.


Syntax
------

.. code-block:: lua

   -- Accessing a specific animation track
   local track = skeleton.tracks[1]

   -- Iterating through all animation tracks
   for i, track in ipairs(skeleton.tracks) do
       if track then
           print("Track " .. i .. " animation:", track.animation)
       end
   end

- ``tracks`` *(read-only)*:
    ``table`` – ``tracks[i]`` is a :doc:`trackEntry/index`, or ``false`` for an empty track.

Example
-------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
   local spineboy = spine.create(skeletonData)

   -- Set an initial animation on track 1 (tracks are 1-based in Lua)
   spineboy:setAnimation(1, "idle", true)

   -- Only track 3 besides track 1: track 2 reads false
   spineboy:setAnimation(3, "blink", false)

   -- Iterate through all tracks and print their animations
   for i, track in ipairs(spineboy.tracks) do
       print("Track " .. i .. " is playing:", track and track.animation)
   end

   -- Adjust the time scale of the first track
   local tracks = spineboy.tracks
   if tracks[1] then
       tracks[1].timeScale = 1.5  -- 150% speed
   end
