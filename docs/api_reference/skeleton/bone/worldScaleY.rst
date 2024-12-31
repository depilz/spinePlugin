===================================
bone.worldScaleY
===================================

| **Type:** number (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

Reflects the bone’s final Y scale in **world space**, after parent scaling is applied.

Example:
........
--------

.. code-block:: lua

   local bone = hero.bones[2]
   print("World Y scale:", bone.worldScaleY)