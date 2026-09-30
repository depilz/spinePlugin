===================================
attachment.yScale
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`scaleY`, :doc:`/naming`

Overview:
.........

``attachment.yScale`` is an alias of :doc:`scaleY` (``attachment.scaleY``): it reads and writes the same scale of a region attachment. Both names work on both plugin lines and
stay supported; :doc:`/naming` explains which name is canonical. The full description is on :doc:`scaleY`.

Example:
--------

.. code-block:: lua

   local attachment = spineboy:findSlot("gun").attachment
   attachment.yScale = 1.5
   print(attachment.yScale, attachment.scaleY)  -- 1.5  1.5
