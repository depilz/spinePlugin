===================================
skeleton:setSkin(skinName)
===================================

| **Type:** Method
| **See also:** :doc:`index`, :doc:`getSkins`

Overview:
.........
--------

Sets the skeleton’s current skin to the specified name. This must match a skin defined in Spine.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:setSkin(skinName)
    
- ``skinName`` *(required)*:
    ``string`` – The name of the skin to apply.

Example:
--------
--------

.. code-block:: lua

   hero:setSkin("warrior")