===================================
bone.b
===================================

| **Type:** ``number`` (read/write)
| **See also:** :doc:`index`, :doc:`/naming`

Overview
--------

The *b* component in the bone’s transform matrix. Adjusting this can shear or skew the bone’s
transform in a more direct matrix-based manner.

Example
-------

.. code-block:: lua

   local bone = spineboy.bones[1]
   bone.b = 0.2
   print("Matrix b:", bone.b)