===================================
bone.xScale
===================================

| **Type:** number (read/write)
| **See also:** :doc:`index`

Overview:
.........
--------

Scale factor along the bone’s local X-axis. Changing `xScale` affects how wide or narrow
attachments appear. A value of `1.0` means no scale.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[2]
   bone.xScale = 2.0  -- Double width