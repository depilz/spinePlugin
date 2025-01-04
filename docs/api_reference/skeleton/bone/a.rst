===================================
bone.a
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

Represents the *a* component of this bone’s local transform matrix. Typically manipulated only
in advanced scenarios for custom transform logic.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[1]
   bone.a = 1.0
   print("Bone matrix 'a':", bone.a)