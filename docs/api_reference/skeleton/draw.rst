===================================
skeleton:draw()
===================================

| **Type:** ``function``
| **See also:** :doc:`skeleton.index`

Overview:
.........
---------

Renders the skeleton’s current state as meshes in Solar2D’s display system. Typically called after
`updateState(deltaTime)` each frame to reflect the most recent animation changes.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:draw()


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
       hero:draw()  -- Render changes
   end
   Runtime:addEventListener("enterFrame", onEnterFrame)