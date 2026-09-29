===================================
bone.worldY
===================================

| **Type:** ``number`` (read-only)
| **See also:** :doc:`index`, :doc:`setWorldPosition`, :doc:`translateWorld`, :doc:`localToWorld`

Overview:
.........

The **world Y position** of the bone, after parent bones and constraints are applied. It is in skeleton space: the
skeleton object's local coordinates, relative to the skeleton's origin. Y grows downwards, as in Solar2D. Use
``skeleton:localToContent()`` to get content coordinates.

The value is recalculated by ``spine.create()``, :doc:`../updateState` and :doc:`../draw`.

This property is read-only: writing it raises ``worldY is read-only; use bone:setWorldPosition(x, y)``. Use
:doc:`setWorldPosition` or :doc:`translateWorld` to move a bone in skeleton space.

Example:
--------

.. code-block:: lua

   local bone = hero.bones[2]
   print("World Y position:", bone.worldY)
