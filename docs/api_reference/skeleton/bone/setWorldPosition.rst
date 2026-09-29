===================================
bone:setWorldPosition()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`translateWorld`, :doc:`worldX`, :doc:`worldY`

Overview:
.........

Moves the bone's origin to a position in skeleton space. The position is converted to the parent bone's coordinates
(for a root bone, to the skeleton's) and written to the bone's local ``x`` and ``y``.

Skeleton space is the skeleton object's local coordinate system, with y growing downwards, the same space as
:doc:`worldX` and :doc:`worldY`. It is not the Solar2D stage: convert touch coordinates with
``skeleton:contentToLocal()`` first, and go back with ``skeleton:localToContent()``.

The write changes only the local pose. ``worldX``, ``worldY``, :doc:`localToWorld`, child bones and
:doc:`../hitTest` see it once the world transform is recalculated by the next :doc:`../updateState` or
:doc:`../draw`. The next animation update overwrites it if an animation keys the bone, so call it after
``updateState`` every frame to hold a position. A bone that is an IK target moves the target, and the constrained
bones follow in the same update. On a bone driven by a constraint or by physics the write is the base pose, which
the constraint may override.

Raises when the bone belongs to a removed skeleton, and for a root bone when the skeleton's scale is zero.

Syntax:
--------

.. code-block:: lua

   bone:setWorldPosition(worldX, worldY)

- ``worldX`` *(required)*:
    ``number`` – The X position in skeleton space.

- ``worldY`` *(required)*:
    ``number`` – The Y position in skeleton space, growing downwards.

Example:
--------

.. code-block:: lua

   -- Drag a bone with the finger
   local crosshair = skeleton:getIKConstraint("aim-ik").target

   local function onTouch(event)
       crosshair:setWorldPosition(skeleton:contentToLocal(event.x, event.y))
       return true
   end
   skeleton:addEventListener("touch", onTouch)
