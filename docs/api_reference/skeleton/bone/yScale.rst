===================================
bone.yScale
===================================

| **Type:** number (read/write)
| **See also:** :doc:`index`

Overview:
.........
--------

Scale factor along the bone’s local Y-axis. Changing `yScale` affects how tall attachments
appear. A value of `1.0` means no vertical scale.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[5]
   bone.yScale = 0.5  -- Half height