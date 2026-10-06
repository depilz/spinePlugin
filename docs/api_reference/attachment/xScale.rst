===================================
attachment.xScale
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`scaleX`, :doc:`/naming`

Overview
--------

``attachment.xScale`` is an alias of :doc:`scaleX` (``attachment.scaleX``): it reads and writes the same scale of a region attachment. Both names work on both plugin lines and
stay supported; :doc:`/naming` explains which name is canonical. The full description is on :doc:`scaleX`.

Example
-------

.. code-block:: lua

   local attachment = spineboy:findSlot("gun").attachment
   attachment.xScale = 1.5
   print(attachment.xScale, attachment.scaleX)  -- 1.5  1.5
