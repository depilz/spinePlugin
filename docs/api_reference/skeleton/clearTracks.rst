===================================
skeleton:clearTracks()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`clearTrack`

Overview:
.........

Stops and removes **all animation tracks** from the skeleton, leaving it with no active
animations. This is a quick way to halt every animation at once.

Syntax:
--------

.. code-block:: lua

   skeleton:clearTracks()

Example:
--------

.. code-block:: lua

   -- Clear all running animations
   print("is animation playing?", spineboy.isActive)
   spineboy:clearTracks()
   spineboy:draw()
   print("track cleared, is animation playing?", spineboy.isActive)