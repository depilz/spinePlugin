===================================
bone.c
===================================

| **Type:** ``number`` (read/write)
| **See also:** :doc:`index`

Overview:
.........
--------

Represents the *c* component in the local transform matrix. Typically used in advanced
transform or shear manipulations.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[2]
   bone.c = 0.1