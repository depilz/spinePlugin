===================================
physics.gravity
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
--------

Defines the **gravity** force applied to the skeleton’s physics constraints.
Setting a positive value simulates downward pull on the bones, while a negative value
will make the bones float upwards.

Example:
........
--------

.. code-block:: lua

   hero.physics.gravity = 0.98
   print("Gravity:", hero.physics.gravity)