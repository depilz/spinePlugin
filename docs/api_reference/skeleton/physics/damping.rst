===================================
physics.damping
===================================

| **Type:** number
| **See also:** :doc:`index`

Overview:
.........
--------

Specifies how quickly motion **damps** over time. A higher damping value causes
bones to lose momentum more rapidly, reducing oscillations.

Example:
--------
--------

.. code-block:: lua

   hero.physics.damping = 2.0
   print("Damping factor:", hero.physics.damping)