===================================
ikConstraint.order
===================================

| **Type:** integer (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

The ordinal of this constraint for the order a skeleton's constraints will be applied by draw.

Example:
--------
--------

.. code-block:: lua

   local ik = hero.ikConstraints[1]
   print("IK constraint order:", ik.order)