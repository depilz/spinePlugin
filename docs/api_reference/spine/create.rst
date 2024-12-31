==========================================
spine.create(skeletonData, [listener])
==========================================

| **Type:** Function
| **Return value:** :doc:`../skeleton/index`
| **See also:** :doc:`index`

Overview:
.........
---------

Creates a new Spine skeleton instance from previously loaded `skeletonData`. Optionally, 
you can provide a listener function to handle animation events such as animation began, 
completed, and custom events triggered within Spine animations.

Gotchas:
--------
--------

Creating multiple skeletons with the same `skeletonData` is efficient, reuse them whenever possible.

Syntax:
-------
-------

.. code-block:: lua

   local skeleton = spine.create(skeletonData, [listener])

- ``skeletonData`` *(required)*:
    ``userdata`` – The SkeletonData userdata returned by ``spine.loadSkeletonData()``.

- ``listener`` *(optional)*:
    ``function`` – A Lua callback function that handles animation events. See :doc:`events` for more details.



Return Value:
--------------
--------------

- ``skeleton`` – A :doc:`../skeleton/index` userdata representing the new Spine skeleton instance.

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   
   -- Load the atlas
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
   
   -- Load skeleton data with a scale factor of 1.0
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas, 1.0)
   
   -- Define a listener function to handle animation events
   local function listener(event)
       if event.name == "spine" then
           if event.phase == "began" then
               print("Animation began:", event.animation)
            elseif event.phase == "ended" then
               print("Animation ended:", event.animation)
            end
       else
           print("Custom event triggered:", event.name) -- prints the custom event name
       end
   end
   
   -- Create the skeleton with the listener
   local hero = spine.create(skeletonData, listener)
   
   -- Position the skeleton in the scene
   hero.x = display.contentCenterX
   hero.y = display.contentCenterY
   
   -- Set an initial animation
   hero:setAnimation(1, "idle", true)
   
   -- Update the skeleton each frame
   local function onEnterFrame(event)
       local deltaTime = event.time / 1000  -- Convert milliseconds to seconds
       hero:updateState(deltaTime)
       hero:draw()
   end
   
   Runtime:addEventListener("enterFrame", onEnterFrame)
