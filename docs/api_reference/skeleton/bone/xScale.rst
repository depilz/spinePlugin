===================================
bone.xScale
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`scaleX`, :doc:`/naming`

Overview:
.........

``bone.xScale`` is an alias of :doc:`scaleX` (``bone.scaleX``): it reads and writes the same local scale. Both names work on both plugin lines and
stay supported; :doc:`/naming` explains which name is canonical. The full description is on :doc:`scaleX`.

Example:
--------

.. code-block:: lua

   local bone = hero.bones[2]
   bone.xScale = 1.5
   print(bone.xScale, bone.scaleX)  -- 1.5  1.5
