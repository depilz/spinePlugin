===================================
spineEvent
===================================

| **Type:** ``table``
| **See also:** :doc:`index`, :doc:`create`

Overview:
.........
--------

This is the event triggered by a Spine animation. You can listen for this event by passing a listener 
function to the :doc:`create` function.


Properties:
-----------
-----------

- **event.name**:
    ``string`` – The name of the event. Either "spine" for all Spine events, or the name of your custom event.

- **event.phase**:
    ``string`` | ``nil`` – The phase of the event. This can be one of the following values:
        - **began**:
            The animation has begun.
        - **ended**:
            The animation has ended.
        - **completed**:
            The animation has completed.
        - **disposed**:
            The animation has been disposed.
        - **interrupted**:
            The animation has been interrupted.
        - **nil**:
            The event is a custom event.

- **event.animation**:
    ``string`` – The name of the animation.

- **event.trackIndex**:
    ``number`` – The track entry number.

- **event.looping**:
    ``boolean`` – The animation is looping.

- **event.target**:
    ``skeleton`` – The :doc:`index` object.



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
