===================================
skeleton:updateState()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`draw`

Overview:
.........

Advances the skeleton’s animation state by `deltaTime` milliseconds, applying all
active animation tracks to the skeleton. Typically followed by `skeleton:draw()`.

It also steps the skeleton's physics constraints by `deltaTime` (scaled by :doc:`physicsTimeScale`) and poses the
skeleton, so bone and slot world values, :doc:`getBounds` and :doc:`getSize` are current as soon as it returns,
even when :doc:`draw` is not called. Physics steps once per ``updateState`` call: calling it several times per frame
steps physics several times, and a frame without ``updateState`` leaves physics where it was. Animation events are
dispatched from ``updateState`` (see :doc:`../spine/event`).

Syntax:
--------

.. code-block:: lua

   skeleton:updateState(deltaTime)

- ``deltaTime`` *(required)*:
     ``number`` – Time elapsed in milliseconds since last update.

Example:
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