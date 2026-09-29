===================================
skeleton.physics
===================================

| **Type:** ``userdata`` or ``nil``
| **See also:** :doc:`index`, :doc:`physics/index`, :doc:`physicsTimeScale`

Overview:
.........

The skeleton's physics constraints as one object: see :doc:`physics/index` for its properties and methods. A write
to it reaches every physics constraint of the skeleton. ``skeleton.physics`` is ``nil`` when the skeleton data has
no physics constraints.

Example:
--------

.. code-block:: lua

   local atlas = spine.loadAtlas("assets/characters/celestial-circus.atlas")
   local data = spine.loadSkeletonData("assets/characters/celestial-circus.json", atlas)
   local circus = spine.create(data)

   print(circus.physics ~= nil)  -- true: this skeleton has physics constraints
   print(hero.physics)           -- nil: the hero has none
