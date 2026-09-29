===================================
ikConstraint.compress
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`

Overview:
.........
--------

When ``compress`` is ``true``, the IK chain can compress, shortening its length
if necessary to reach the target more easily.

Example:
--------
--------

.. code-block:: lua

   local ik = hero.ikConstraints[3]
   ik.compress = true