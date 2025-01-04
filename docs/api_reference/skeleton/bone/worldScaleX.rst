===================================
bone.worldScaleX
===================================

| **Type:** ``number`` (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

Reflects the bone’s final X scale in **world space**, combining local scale with any parent
scale transformations.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[2]
   print("World X scale:", bone.worldScaleX)