===================================
skeleton:updateState()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`draw`

Overview:
.........
---------

Advances the skeleton’s animation state by `deltaTime` milliseconds, applying all
active animation tracks to the skeleton. Typically followed by `skeleton:draw()`.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:updateState(deltaTime)

- ``deltaTime`` *(required)*:
     ``number`` – Time elapsed in milliseconds since last update.

Example:
--------
--------

.. code-block:: lua

   local lastTime = system.getTimer()
   local function onEnterFrame(event)
       local now = system.getTimer()
       local dt = now - lastTime
       lastTime = now

       hero:updateState(dt)
       hero:draw()
   end
   Runtime:addEventListener("enterFrame", onEnterFrame)