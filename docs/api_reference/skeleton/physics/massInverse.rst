===================================
physics.massInverse
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........

Represents the inverse of mass applied to the constraints. A higher `massInverse`
means the bones behave as if they’re lighter or more easily accelerated by forces.

Example:
--------

.. code-block:: lua

   -- the hero has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   circus.physics.massInverse = 1.2
   print("Mass Inverse:", circus.physics.massInverse)