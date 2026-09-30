===================================
skeleton:clearTrack()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`clearTracks`

Overview:
.........

Stops and removes the animation on a **single** track. This is
useful if you want to cancel an animation on one track but leave others running.

Syntax:
--------

.. fragment: syntax line; trackIndex is a placeholder
.. code-block:: lua

   skeleton:clearTrack(trackIndex)

- ``trackIndex`` *(required)*:
    ``number`` – The track index to clear.

Example:
--------

.. code-block:: lua

   spineboy:setAnimation(1, "walk", true)
   spineboy:setAnimation(2, "shoot", true)

   -- Clear the "shoot" animation
   spineboy:clearTrack(2)
   spineboy:draw()