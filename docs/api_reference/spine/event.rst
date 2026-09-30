===================================
spineEvent
===================================

| **Type:** ``table``
| **See also:** :doc:`index`, :doc:`create`, :doc:`../skeleton/setListener`, :doc:`../skeleton/trackEntry/onComplete`, :doc:`/naming`

Overview:
.........

This is the event triggered by a Spine animation. Every event has ``event.name == "spine"``; ``event.phase`` tells
what happened. You can receive it in three places:

- the listener function passed to :doc:`create` or :doc:`../skeleton/setListener`;
- ``skeleton:addEventListener("spine", listener)``, like any other Solar2D event;
- the entry's :doc:`../skeleton/trackEntry/onComplete` function, for that entry's ``completed`` events only.


Properties:
-----------

- **event.name**:
    ``string`` – Always ``"spine"``.

- **event.phase**:
    ``string`` – What happened. One of:
        - **began**:
            The animation has begun.
        - **ended**:
            The animation has ended.
        - **completed**:
            The animation has completed. A looping animation completes at the end of every loop.
        - **disposed**:
            The animation has been disposed.
        - **interrupted**:
            The animation has been interrupted.
        - **event**:
            A custom event keyed in the animation fired. See `Custom event properties`_.

- **event.target**:
    ``skeleton`` – The :doc:`../skeleton/index` display object returned by :doc:`create`, so
    ``event.target == skeleton``. The plugin releases this reference when the skeleton is freed
    (see :doc:`../../lifecycle`).

- **event.animation**:
    ``string`` – The name of the animation.

- **event.trackIndex**:
    ``number`` – The 1-based track index, as :doc:`../skeleton/trackEntry/trackIndex`.

- **event.loop**:
    ``boolean`` – The animation is looping, as :doc:`../skeleton/trackEntry/loop`. Not set on custom events.

- **event.looping**:
    ``boolean`` – An alias of ``event.loop``, with the same value (see :doc:`/naming`).


Custom event properties
=======================

When ``event.phase == "event"``, the event also carries:

- **event.event**:
    ``string`` – The name of the custom event, as set in the Spine editor. A custom event named ``"spine"``
    arrives as ``event.event == "spine"`` and collides with nothing.

- **event.int**:
    ``number`` – The integer value of this key.

- **event.float**:
    ``number`` – The float value of this key.

- **event.string**:
    ``string`` – The string value of this key.

- **event.time**:
    ``number`` – The time of this key in the animation, in milliseconds.

The values are the ones set on the key that fired. A key that sets no value of its own has the event's default
value from the Spine editor.


Audio event properties
=======================

A custom event with an audio path also carries:

- **event.audioPath**:
    ``string`` – The path to the audio file.

- **event.volume**:
    ``number`` – The volume of this key.

- **event.balance**:
    ``number`` – The balance of this key.

For a key that sets no volume or balance of its own in ``.json`` data, the 4.2 line reports ``1`` and ``0`` while
the 4.3 line reports the event's default volume and balance. This is how each Spine runtime reads the file.


Dispatch order:
---------------

For each Spine event, the plugin builds **one** event table and passes it to every listener, in this order:

1. the entry's :doc:`../skeleton/trackEntry/onComplete` function (``completed`` events only);
2. the listener passed to :doc:`create` or set with :doc:`../skeleton/setListener`;
3. the skeleton's own ``dispatchEvent``: the ``"spine"`` function listeners in the order they were added, then the
   ``"spine"`` table listeners in the order they were added. This is Solar2D's order for every event.

Because the table is shared, a change a listener makes to it (``event.foo = 1``) is visible to the listeners after
it. ``event.target`` is set before the first listener runs.

If a listener removes the skeleton, the later steps of that list do not run for this event, and no further events
are dispatched. A ``removeSelf()`` inside a ``"spine"`` listener added with ``addEventListener`` does not stop the
rest of that one ``dispatchEvent``: Solar2D calls every listener it collected (the skeleton is freed later, see
:doc:`../../lifecycle`).


Errors in the listener:
-----------------------

If any listener raises an error, Solar2D reports it like any other listener error (see
:doc:`../../lifecycle`). An error in a ``"spine"`` listener added with ``addEventListener`` ends that one
``dispatchEvent``, as in Solar2D. The plugin call that dispatched the event does not raise, and the next events are
still dispatched.


Example:
--------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")

   -- Load the atlas
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")

   -- Load skeleton data with a scale factor of 1.0
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas, 1.0)

   -- Define a listener function to handle animation events
   local function listener(event)
       if event.phase == "event" then
           print("Custom event triggered:", event.event, event.int, event.float, event.string, event.time)
       elseif event.phase == "began" then
           print("Animation began:", event.animation)
       elseif event.phase == "ended" then
           print("Animation ended:", event.animation)
       end
   end

   -- Create the skeleton with the listener
   local spineboy = spine.create(skeletonData, listener)

   -- Or listen like any other display object
   spineboy:addEventListener("spine", function(event)
       if event.phase == "completed" then
           print("Animation completed:", event.animation)
       end
   end)

   -- Position the skeleton in the scene
   spineboy.x = display.contentCenterX
   spineboy.y = display.contentCenterY

   -- Set an initial animation
   spineboy:setAnimation(1, "idle", true)

   -- Update the skeleton each frame
   local lastTime = system.getTimer()
   local function onEnterFrame(event)
       local now = system.getTimer()
       local deltaTime = now - lastTime -- milliseconds
       lastTime = now
       spineboy:updateState(deltaTime)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)
