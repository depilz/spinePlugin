===================================
physics.damping
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

Specifies how quickly motion **damps** over time. A higher damping value causes
bones to lose momentum more rapidly, reducing oscillations.

Example
-------

.. code-block:: lua

   -- spineboy has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   circus.physics.damping = 2.0
   print("Damping factor:", circus.physics.damping)