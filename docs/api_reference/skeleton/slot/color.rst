===================================
slot.color
===================================

| **Type:** ``table``
| **See also:** :doc:`index`, :doc:`r`, :doc:`g`, :doc:`b`, :doc:`a`, :doc:`/naming`

Overview
--------

The RGBA components of this slot’s color: ``{ r = 0–1, g = 0–1, b = 0–1, a = 0–1 }``.

Reading returns a new table; changing a value in that table does not change the slot. Writing a table sets the
slot's color: each of ``r``, ``g``, ``b`` and ``a`` that the table holds as a number is set, and the others keep
their value. :doc:`r`, :doc:`g`, :doc:`b` and :doc:`a` read and write the same color one component at a time (:doc:`alpha` is an alias of :doc:`a`).

Example
-------

.. code-block:: lua

   local c = spineboy.slots[2].color
   print(("Slot color RGBA: %f, %f, %f, %f"):format(c.r, c.g, c.b, c.a))

   spineboy.slots[2].color = { r = 1, g = 0.5, b = 0.5 }  -- a red tint; alpha keeps its value