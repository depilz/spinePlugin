===================================
bone.shearY
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........

Represents the **shear** along the bone’s Y-axis. This skews attachments vertically for
stylized stretching or angled shapes.

Example:
........

.. code-block:: lua

   local legBone = spineboy.bones[6]
   legBone.shearY = -5