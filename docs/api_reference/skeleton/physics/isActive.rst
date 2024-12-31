===================================
physics.isActive
===================================

| **Type:** boolean
| **See also:** :doc:`index`

Overview:
.........
--------

Indicates whether physics is currently **active** on the constraints. By default,
this is set to **true**, but can be toggled on and off as needed.

Example:
--------
--------

.. code-block:: lua

   -- Disable physics
   hero.physics.isActive = false

   -- Re-enable physics
   hero.physics.isActive = true