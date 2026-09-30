===================================
physics.wind
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........

The **wind** force applied to all physics constraints. This is commonly used to simulate wind
or directional forces on bones in a skeleton.

Example:
--------

.. code-block:: lua

   -- spineboy has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   -- Increase wind force
   circus.physics.wind = 0.3

   -- Print current wind
   print("Wind value:", circus.physics.wind)