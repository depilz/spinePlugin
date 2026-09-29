==========================================
spine.create()
==========================================

| **Type:** ``function``
| **Return value:** :doc:`../skeleton/index`
| **See also:** :doc:`index`

Overview:
.........

Creates a new Spine skeleton instance from previously loaded `skeletonData`. Optionally,
you can provide a listener function to handle animation events such as animation began,
completed, and custom events triggered within Spine animations.

Gotchas:
--------

Creating multiple skeletons with the same `skeletonData` is efficient, reuse them whenever possible.

The skeleton is freed on the frame after it is removed, not at once. See :doc:`../../lifecycle`
for what still works during that window.

The new skeleton is already posed: bone and slot world values, :doc:`../skeleton/getBounds` and
:doc:`../skeleton/getSize` are current right after ``create()``. Physics does not step until the first
:doc:`../skeleton/updateState`.

Syntax:
-------

.. fragment: syntax line; arguments are placeholders
.. code-block:: lua

   local skeleton = spine.create(skeletonData, [listener])

- ``skeletonData`` *(required)*:
    ``userdata`` – The SkeletonData userdata returned by ``spine.loadSkeletonData()``.

- ``listener`` *(optional)*:
    ``function`` – A Lua callback function that handles animation events. See :doc:`event` for more details.
    Any other non-``nil`` value raises an error. It runs before the ``"spine"`` listeners added with
    ``skeleton:addEventListener``; :doc:`../skeleton/setListener` replaces or clears it later.



Return Value:
--------------

- ``skeleton`` – A :doc:`../skeleton/index` display object representing the new Spine skeleton instance.

Example:
--------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")

   -- Load the atlas
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")

   -- Load skeleton data with a scale factor of 1.0
   local skeletonData = spine.loadSkeletonData("assets/characters/hero.skel", atlas, 1.0)

   -- Define a listener function to handle animation events
   local function listener(event)
       if event.phase == "event" then
           print("Custom event triggered:", event.event) -- prints the custom event name
       elseif event.phase == "began" then
           print("Animation began:", event.animation)
       elseif event.phase == "ended" then
           print("Animation ended:", event.animation)
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
   local lastTime = system.getTimer()
   local function onEnterFrame(event)
       local now = system.getTimer()
       local deltaTime = now - lastTime -- milliseconds
       lastTime = now
       hero:updateState(deltaTime)
       hero:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)
