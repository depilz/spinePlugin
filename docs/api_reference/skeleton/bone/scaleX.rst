===================================
bone.scaleX
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`xScale`, :doc:`/naming`

Overview:
.........

Scale factor along the bone's local X-axis, relative to its parent bone. Changing ``scaleX`` affects how wide or narrow attachments appear. A value of ``1.0`` means
no scale. ``bone.xScale`` is an alias of ``bone.scaleX``: it reads and writes the same value.

Example:
--------

.. code-block:: lua

   local bone = spineboy.bones[2]
   bone.scaleX = 2.0  -- double width
