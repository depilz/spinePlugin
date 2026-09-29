===================================
physics.xVelocity
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`/naming`

Overview:
.........

The horizontal (X-axis) velocity applied to the physics constraints.

Example:
--------

.. code-block:: lua

   -- the hero has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   circus.physics.xVelocity = 10
   print("X Velocity:", circus.physics.xVelocity)