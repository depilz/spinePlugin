===================================
physics.mix
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

Adjusts the **mix** factor for the physics constraints, determining how much
physics influences the bones versus their original animation or transforms.

Example:
--------
--------

.. code-block:: lua

   hero.physics.mix = 0.5
   print("Physics mix:", hero.physics.mix)