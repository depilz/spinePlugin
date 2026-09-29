===================================
physics:translate()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`rotate`

Overview:
.........

Translates all physics constraints by the given `(x, y)` offset.


Syntax:
--------

.. fragment: syntax line; physics and the arguments are placeholders
.. code-block:: lua

   physics:translate(x, y)

- ``x`` *(required)*:
    ``number`` – The horizontal translation offset.
- ``y`` *(required)*:
    ``number`` – The vertical translation offset.

Example:
--------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")

   -- the hero has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   -- Move physics constraints 10 units right, 20 units up
   circus.physics:translate(10, -20)