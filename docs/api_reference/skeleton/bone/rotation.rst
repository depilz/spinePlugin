===================================
bone.rotation
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

Rotation in **degrees**, relative to the parent bone. A value of `0` means no rotation; a
positive or negative number rotates the bone around its local origin.

Example:
--------
--------

.. code-block:: lua

   local armBone = hero.bones[4]
   armBone.rotation = armBone.rotation + 15
   print("Arm rotation:", armBone.rotation)