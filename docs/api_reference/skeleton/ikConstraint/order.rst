===================================
ikConstraint.order
===================================

| **Type:** ``number`` (read-only)
| **See also:** :doc:`index`

Overview:
.........

The ordinal of this constraint for the order a skeleton's constraints will be applied by draw.

Example:
--------

.. code-block:: lua

   local ik = spineboy.ikConstraints[1]
   print("IK constraint order:", ik.order)