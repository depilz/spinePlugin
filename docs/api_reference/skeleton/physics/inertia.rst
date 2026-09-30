===================================
physics.inertia
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........

The **inertia** property affects how resistant the physics constraints are to changes
in motion. Higher inertia makes bones slower to start or stop moving.

Example:
--------

.. code-block:: lua

   -- spineboy has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   circus.physics.inertia = 0.7
   print("Inertia:", circus.physics.inertia)