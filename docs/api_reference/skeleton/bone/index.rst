===================================
bone
===================================

| **Type:** userdata
| **See also:** :doc:`../bones`, :doc:`../index`

Overview:
..........

A **Bone** object represents one bone in the Spine skeleton’s transform hierarchy. Each
bone has position, rotation, scale, and shear values, as well as references to a parent bone
and matrix components that affect how child bones and attachments are transformed.

Below are all the properties exposed by a Bone. Most can be **read and/or written**. Some
properties (like ``name`` or ``parent``) are read-only.

Local properties such as ``x`` and ``y`` are the bone's pose relative to its parent bone. World properties such as
``worldX`` and ``worldY`` are in skeleton space: the skeleton object's local coordinates, with y growing downwards.
They are read-only; use :doc:`setWorldPosition` or :doc:`translateWorld` to move a bone in skeleton space.

Properties:
-----------

**Common**

.. toctree::
   :maxdepth: 1

   name
   parent
   children
   x
   y
   rotation
   scaleX
   scaleY
   worldX
   worldY
   worldRotation
   worldScaleX
   worldScaleY

**Advanced**

.. toctree::
   :maxdepth: 1

   shearX
   shearY
   appliedRotation
   a
   b
   c
   d

Methods:
--------

.. toctree::
   :maxdepth: 1

   setWorldPosition
   translateWorld
   localToWorld
   worldToLocal

Aliases:
--------

See :doc:`/naming`.

.. toctree::
   :maxdepth: 1

   xScale
   yScale
