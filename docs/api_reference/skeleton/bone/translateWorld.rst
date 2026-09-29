===================================
bone:translateWorld()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setWorldPosition`, :doc:`worldX`, :doc:`worldY`

Overview:
.........

Moves the bone's origin by an offset in skeleton space. It is :doc:`setWorldPosition` with the bone's current world
position plus the offset. That position is taken from the bone's local pose, so several calls before the next
update add up.

Skeleton space is the skeleton object's local coordinate system, with y growing downwards. Like
:doc:`setWorldPosition` it writes the local pose only: the world values are recalculated by the next
:doc:`../updateState` or :doc:`../draw`, and an animation keying the bone overwrites the write on its next update.

Raises when the bone belongs to a removed skeleton, and for a root bone when the skeleton's scale is zero.

Syntax:
--------

.. code-block:: lua

   bone:translateWorld(deltaX, deltaY)

- ``deltaX`` *(required)*:
    ``number`` – The X offset in skeleton space.

- ``deltaY`` *(required)*:
    ``number`` – The Y offset in skeleton space, growing downwards.

Example:
--------

.. code-block:: lua

   -- Move the bone 20 units right and 10 units down
   bone:translateWorld(20, 10)
