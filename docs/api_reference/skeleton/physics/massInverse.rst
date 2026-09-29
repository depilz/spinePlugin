===================================
physics.massInverse
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

Represents the inverse of mass applied to the constraints. A higher `massInverse`
means the bones behave as if they’re lighter or more easily accelerated by forces.

Example:
--------
--------

.. code-block:: lua

   hero.physics.massInverse = 1.2
   print("Mass Inverse:", hero.physics.massInverse)