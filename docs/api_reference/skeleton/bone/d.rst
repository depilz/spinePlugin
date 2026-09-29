===================================
bone.d
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

The *d* component of the bone’s transform matrix, often involved in scaling or shear in the Y
direction.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[3]
   bone.d = 1.0
   print("Bone matrix d:", bone.d)