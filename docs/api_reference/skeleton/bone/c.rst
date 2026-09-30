===================================
bone.c
===================================

| **Type:** ``number`` (read/write)
| **See also:** :doc:`index`, :doc:`/naming`

Overview:
.........

Represents the *c* component in the local transform matrix. Typically used in advanced
transform or shear manipulations.

Example:
--------

.. code-block:: lua

   local bone = spineboy.bones[2]
   bone.c = 0.1