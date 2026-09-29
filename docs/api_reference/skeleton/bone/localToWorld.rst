===================================
bone:localToWorld()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`worldToLocal`, :doc:`setWorldPosition`

Overview:
.........

Converts a point from the bone's own coordinate system to skeleton space, the skeleton object's local coordinates
with y growing downwards. It uses the bone's current world transform, the one recalculated by
:doc:`../updateState`, :doc:`../draw` and ``spine.create()``. Use ``skeleton:localToContent()`` on the result to get
content coordinates.

Raises when the bone belongs to a removed skeleton.

Syntax:
--------

.. fragment: syntax line; bone, localX and localY are placeholders
.. code-block:: lua

   local worldX, worldY = bone:localToWorld(localX, localY)

- ``localX``, ``localY`` *(required)*:
    ``number`` – The point in the bone's coordinate system.

Returns ``worldX``, ``worldY``: the point in skeleton space.

Example:
--------

.. code-block:: lua

   -- The content position of a point 50 units along the hand bone
   local bone = skeleton:findSlot("hand1").bone
   local x, y = skeleton:localToContent(bone:localToWorld(50, 0))
