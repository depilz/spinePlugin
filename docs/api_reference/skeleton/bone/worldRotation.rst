===================================
bone.worldRotation
===================================

| **Type:** ``number`` (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

The **world rotation** of the bone. This is the bone's rotation relative to the skeleton's origin.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[2]
   print("World rotation:", bone.worldRotation)