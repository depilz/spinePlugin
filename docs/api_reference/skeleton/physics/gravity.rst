===================================
physics.gravity
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

Defines the **gravity** force applied to the skeleton’s physics constraints.
A positive value pulls the bones down on screen, as in the Spine editor, while a negative value
makes them float upwards.

.. only:: spine42

   .. note::

      Plugin 1.5.0 on the 4.2 line (``plugin.spine42``) applied gravity upward on screen: a positive
      value lifted the bones. The 4.2 line now uses Spine's native Y-down mode, so gravity pulls down.

Example
-------

.. code-block:: lua

   -- spineboy has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   circus.physics.gravity = 0.98
   print("Gravity:", circus.physics.gravity)