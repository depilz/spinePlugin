===================================
slot.alpha
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`color`, :doc:`a`, :doc:`/naming`

Overview:
.........

``slot.alpha`` is an alias of :doc:`a` (``slot.a``): it reads and writes the alpha channel of the slot's color. Both names work on both plugin lines and
stay supported; :doc:`/naming` explains which name is canonical. The full description is on :doc:`a`.

Example:
--------

.. code-block:: lua

   local slot = spineboy.slots[1]
   slot.alpha = 0.8
   print(slot.alpha, slot.a)  -- both 0.8
