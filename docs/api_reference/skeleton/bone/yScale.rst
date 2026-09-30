===================================
bone.yScale
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`scaleY`, :doc:`/naming`

Overview:
.........

``bone.yScale`` is an alias of :doc:`scaleY` (``bone.scaleY``): it reads and writes the same local scale. Both names work on both plugin lines and
stay supported; :doc:`/naming` explains which name is canonical. The full description is on :doc:`scaleY`.

Example:
--------

.. code-block:: lua

   local bone = spineboy.bones[2]
   bone.yScale = 1.5
   print(bone.yScale, bone.scaleY)  -- 1.5  1.5
