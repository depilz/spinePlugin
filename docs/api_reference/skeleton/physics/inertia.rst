===================================
physics.inertia
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
--------

The **inertia** property affects how resistant the physics constraints are to changes
in motion. Higher inertia makes bones slower to start or stop moving.

Example:
--------
--------

.. code-block:: lua

   hero.physics.inertia = 0.7
   print("Inertia:", hero.physics.inertia)