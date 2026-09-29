===================================
physics:rotate()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`translate`

Overview:
.........

Rotates all physics constraints around the point `(x, y)` by the specified `degrees`.

Syntax:
--------

.. fragment: syntax line; physics and the arguments are placeholders
.. code-block:: lua

   physics:rotate(x, y, degrees)

- ``x`` *(required)*:
    ``number`` – The pivot’s X coordinate.
- ``y`` *(required)*:
    ``number`` – The pivot’s Y coordinate.
- ``degrees`` *(required)*:
    ``number`` – Degrees to rotate around the pivot.

Example:
--------

.. code-block:: lua

   -- the hero has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   -- Rotate the physics system around (100, 200) by 45 degrees
   circus.physics:rotate(100, 200, 45)