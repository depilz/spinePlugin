===================================
bone.shearX
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

Represents the **shear** along the bone’s X-axis. This skews the bone horizontally, altering
the shape of attachments in a non-uniform way.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[3]
   bone.shearX = 10
   print("Shear X:", bone.shearX)