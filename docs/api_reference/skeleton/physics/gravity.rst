===================================
physics.gravity
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........

Defines the **gravity** force applied to the skeleton’s physics constraints.
A positive value pulls the bones down on screen, as in the Spine editor, while a negative value
makes them float upwards.

.. note::

   Plugin 1.5.0 on the 4.2 line (``plugin.spine42``) applied gravity upward on screen: a positive
   value lifted the bones. The 4.2 line now uses Spine's native Y-down mode, so gravity pulls down.

Example:
........

.. code-block:: lua

   hero.physics.gravity = 0.98
   print("Gravity:", hero.physics.gravity)