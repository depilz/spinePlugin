===================================
bone
===================================

Overview
........
--------

A **Bone** object represents one bone in the Spine skeleton’s transform hierarchy. Each
bone has position, rotation, scale, and shear values, as well as references to a parent bone
and matrix components that affect how child bones and attachments are transformed.

Below are all the properties exposed by a Bone. Most can be **read and/or written**. Some
properties (like ``name`` or ``parent``) are read-only.

Properties
----------
----------

**Common**

.. toctree::
   :maxdepth: 1

   name
   parent
   x
   y
   rotation
   xScale
   yScale
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