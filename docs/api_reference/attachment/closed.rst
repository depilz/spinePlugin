=======================================
attachment.closed
=======================================

| **Type:** ``boolean`` (read/write)
| **Attachment Types:** path

Indicates whether the path forms a closed loop.

When ``true``, the path connects back to its starting point, forming a continuous
loop. When ``false``, the path has distinct start and end points.

This affects how path constraints and path followers behave, particularly at the
ends of the path.

The examples use the mix-and-match example skeleton, whose arms and legs follow path attachments.

Example
-------

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local pathSlot = girl:findSlot("arm-front-path")
   local path = pathSlot.attachment

   if path and path.type == "path" then
       if path.closed then
           print("Path is a closed loop")
           -- Followers will wrap around
       else
           print("Path has start and end points")
           -- Followers will stop at the ends
       end

       -- Toggle closed state
       path.closed = not path.closed
   end

**Path constraint example:**

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local trackPath = girl:findSlot("arm-front-path").attachment

   if trackPath and trackPath.type == "path" then
       -- Make it a closed circuit
       trackPath.closed = true

       -- Now path constraints can loop around continuously
   end

Notes
-----

- Set in the Spine editor but can be modified at runtime
- Affects path constraint behavior
- Closed paths are suitable for circular/looping movements
- Open paths are suitable for one-way movements

See Also
--------

- :doc:`constantSpeed` - Whether to use constant speed along path
- :doc:`lengths` - The curve segment lengths

