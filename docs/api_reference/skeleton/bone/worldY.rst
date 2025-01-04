===================================
bone.worldY
===================================

| **Type:** ``number`` (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

The **world Y position** of the bone. This is the bone's Y position relative to the skeleton's origin.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[2]
   print("World Y position:", bone.worldY)