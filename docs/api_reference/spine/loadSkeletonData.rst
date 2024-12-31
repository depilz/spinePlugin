===============================================
spine.loadSkeletonData(path, atlas, [scale])
===============================================

| **Type:** Function
| **Return value:** SkeletonData userdata
| **See also:** :doc:`index`, :doc:`loadAtlas`

Overview:
.........
---------

Loads Spine skeleton data (``.json`` or ``.skel``) from the specified path using a previously loaded atlas. This function parses the skeleton data and prepares it for animation within your Solar2D project. Optionally, you can provide a scale factor to adjust the size of the skeleton.

Gotchas:
--------
--------

The referenced atlas and the skeleton data will remain alive as long as this object is 
alive or has references to it. 

The scale, if provided, will affect all skeletons created with this skeleton data. Alternatively you
can scale the skeleton instance directly.

Syntax:
-------
-------

.. code-block:: lua

   local skeletonData = spine.loadSkeletonData(path, atlas, [scale])

- ``path`` *(required)*:
    ``string`` – The relative path to your skeleton data file (either ``.json`` or ``.skel``).

- ``atlas`` *(required)*:
    ``userdata`` – The atlas userdata returned by ``spine.loadAtlas()``. This atlas contains texture information required by the skeleton.

- ``scale`` *(optional)*:
    ``number`` – A scaling factor to apply to the skeleton. Defaults to ``1.0`` if not provided.

Return Values:
--------------
--------------

- ``userdata`` – A Lua userdata wrapping the underlying C++ ``SkeletonData`` object. This userdata is used when creating skeleton instances with ``spine.create()``.

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   
   -- Load the atlas
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   
   -- Load skeleton data with a scale factor of 0.75
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas, 0.75)
   
   -- Create the skeleton
   local hero = spine.create(skeletonData)
   
   -- Set an animation
   hero:setAnimation(0, "walk", true)
   
   -- Update the skeleton each frame
   local function onEnterFrame(event)
       local deltaTime = event.time / 1000  -- Convert milliseconds to seconds
       hero:updateState(deltaTime)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)