===================================
bone:worldToLocal()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`localToWorld`, :doc:`setWorldPosition`

Overview:
.........

Converts a point from skeleton space, the skeleton object's local coordinates with y growing downwards, to the
bone's own coordinate system. It uses the bone's current world transform, the one recalculated by
:doc:`../updateState`, :doc:`../draw` and ``spine.create()``. Convert content coordinates with
``skeleton:contentToLocal()`` first.

The result is relative to the bone itself. To move the bone, use :doc:`setWorldPosition`, which converts to the
parent bone's coordinates.

Raises when the bone belongs to a removed skeleton.

Syntax:
--------

.. code-block:: lua

   local localX, localY = bone:worldToLocal(worldX, worldY)

- ``worldX``, ``worldY`` *(required)*:
    ``number`` – The point in skeleton space.

Returns ``localX``, ``localY``: the point in the bone's coordinate system.

Example:
--------

.. code-block:: lua

   -- Where a touch lands relative to the bone
   local localX, localY = bone:worldToLocal(skeleton:contentToLocal(event.x, event.y))
