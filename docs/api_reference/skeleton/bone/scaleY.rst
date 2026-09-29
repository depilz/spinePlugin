===================================
bone.scaleY
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`yScale`, :doc:`/naming`

Overview:
.........

Scale factor along the bone's local Y-axis, relative to its parent bone. Changing ``scaleY`` affects how tall attachments appear. A value of ``1.0`` means
no scale. ``bone.yScale`` is an alias of ``bone.scaleY``: it reads and writes the same value.

Example:
--------

.. code-block:: lua

   local bone = hero.bones[5]
   bone.scaleY = 0.5  -- half height
