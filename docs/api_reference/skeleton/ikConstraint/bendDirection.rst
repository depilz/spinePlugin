===================================
ikConstraint.bendDirection
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

Indicates whether bones bend **forward** (`1`) or **backward** (`-1`). 
Useful if you want the IK chain to flip how it curves around the target.

Example:
--------
--------

.. code-block:: lua

   local legIK = hero.ikConstraints[1]
   legIK.bendDirection = -1  -- Force the leg to bend the other way