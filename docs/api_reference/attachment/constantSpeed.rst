=======================================
attachment.constantSpeed
=======================================

| **Type:** ``boolean`` (read/write)
| **Attachment types:** path

Overview
--------

Determines whether movement along the path should be at constant speed.

When ``true``, movement along the path is adjusted so that the speed appears
constant despite varying curve lengths. When ``false``, movement follows the
path's natural parameterization, which may vary in speed.

This is primarily used by path constraints to control how bones follow the path.

The examples use the mix-and-match example skeleton, whose arms and legs follow path attachments.

Example
-------

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local pathSlot = girl:findSlot("arm-front-path")
   local path = pathSlot.attachment

   if path and path.type == "path" then
       if path.constantSpeed then
           print("Path uses constant speed movement")
       else
           print("Path uses natural parameterization")
       end

       -- Enable constant speed for smoother animation
       path.constantSpeed = true
   end

**Animation example:**

.. code-block:: lua

   -- For a path that an object follows
   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local trackPath = girl:findSlot("arm-front-path").attachment

   if trackPath and trackPath.type == "path" then
       -- Constant speed gives more predictable motion
       trackPath.constantSpeed = true

       print("Path lengths:", table.concat(trackPath.lengths, ", "))
   end

Notes
-----

- Set in the Spine editor but can be modified at runtime
- Primarily affects path constraint behavior
- Constant speed mode is more computationally expensive
- Recommended for paths with varying curve lengths when smooth motion is desired

See also
--------

- :doc:`closed` - Whether the path is a closed loop
- :doc:`lengths` - The curve segment lengths used for constant speed

