===================================
skeleton.physicsTimeScale
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`timeScale`, :doc:`physics/index`

Overview:
.........

The **physicsTimeScale** attribute scales the time step of the skeleton's Spine physics constraints.
It defaults to ``1`` (real time). ``2`` runs physics twice as fast, ``0.5`` at half speed, and ``0``
pauses it. It only affects Spine physics constraints; the playback speed of animations is
:doc:`timeScale`, which does not scale physics.

Physics advances in :doc:`updateState` whether or not an animation is playing, so a skeleton with
physics and no animation tracks still simulates.

``physicsTimeScale = 0`` pauses physics without a catch-up: when it goes back above ``0``, physics
continues from where it stopped instead of simulating the paused time in one step (as happens when
:doc:`physics/mix` returns above ``0``).

The value must be a finite number ``>= 0``; writing anything else raises
``physicsTimeScale must be a finite number >= 0``.

Example:
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- Pause the hero's physics (hair, cloth) while the animation keeps playing
   hero.physicsTimeScale = 0

   -- Resume it later, at half speed
   hero.physicsTimeScale = 0.5
