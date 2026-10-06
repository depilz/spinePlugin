===================================
physics.strength
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

Controls the **strength** of the physics constraints, determining how strongly
bones try to return to their original positions.

Example
-------

.. code-block:: lua

   -- spineboy has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   circus.physics.strength = 1.5
   print("Physics constraint strength:", circus.physics.strength)