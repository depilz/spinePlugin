===================================
skeleton:setBonesToSetupPose()
===================================

| **Type:** Method
| **See also:** :doc:`index`, :doc:`setToSetupPose`, :doc:`setSlotsToSetupPose`

Overview:
.........
--------

Resets **only the bones** of the skeleton to their setup pose, leaving slot attachments
untouched. This is handy if you only want to restore bone transforms but keep the current
visual attachments.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:setBonesToSetupPose()

Example:
--------
--------

.. code-block:: lua

   -- Reset just the bones, preserving the slot attachments
   hero:setBonesToSetupPose()