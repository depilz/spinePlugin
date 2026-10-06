===================================
physics.yVelocity
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`/naming`

Overview
--------

The vertical (Y-axis) velocity applied to the physics constraints.

Example
-------

.. code-block:: lua

   -- spineboy has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   circus.physics.yVelocity = 10
   print("Y Velocity:", circus.physics.yVelocity)