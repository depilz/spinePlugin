===================================
skeleton:clearTrack()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`clearTracks`

Overview:
.........
--------

Stops and removes the animation on a **single** track. This is
useful if you want to cancel an animation on one track but leave others running.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:clearTrack(trackIndex)

- ``trackIndex`` *(required)*:
    ``number`` – The track index to clear.

Example:
--------
--------

.. code-block:: lua

    hero:setAnimation("walk", 1, true, 1)
    hero:setAnimation("run", 2, true, 1)

   -- Clear the "run" animation
   hero:clearTrack(2)
   hero:draw()