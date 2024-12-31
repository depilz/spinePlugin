===================================
physics.wind
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
---------

The **wind** force applied to all physics constraints. This is commonly used to simulate wind 
or directional forces on bones in a skeleton.

Example:
--------
--------

.. code-block:: lua

   -- Increase wind force
   hero.physics.wind = 0.3
   
   -- Print current wind
   print("Wind value:", hero.physics.wind)