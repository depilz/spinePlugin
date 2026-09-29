=======================================
attachment.constantSpeed
=======================================

| **Type:** ``boolean`` (read/write)
| **Attachment Types:** path

Determines whether movement along the path should be at constant speed.

When ``true``, movement along the path is adjusted so that the speed appears
constant despite varying curve lengths. When ``false``, movement follows the
path's natural parameterization, which may vary in speed.

This is primarily used by path constraints to control how bones follow the path.

Example
-------

.. code-block:: lua

   local pathSlot = skeleton:findSlot("weapon-morningstar-path")
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
   local trackPath = skeleton:findSlot("weapon-morningstar-path").attachment

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

See Also
--------

- :doc:`closed` - Whether the path is a closed loop
- :doc:`lengths` - The curve segment lengths used for constant speed

