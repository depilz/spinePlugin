===================================
skeleton:setSlotsToSetupPose()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setToSetupPose`, :doc:`setBonesToSetupPose`

Overview:
.........
--------

Resets **only the slots** of the skeleton to their setup pose, preserving bone transforms.
Use this if you want to restore default attachments but keep the current bone positions.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:setSlotsToSetupPose()

Example:
--------
--------

.. code-block:: lua

   -- Restore default slot attachments
   hero:setSlotsToSetupPose()