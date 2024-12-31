===================================
skeleton:getIKConstraintNames()
===================================

| **Type:** Method
| **See also:** :doc:`index`, :doc:`getIKConstraint`

Overview:
.........
---------

Returns an array of all IK constraint names in this skeleton’s data.

Syntax:
--------
--------

.. code-block:: lua

   local names = skeleton:getIKConstraintNames()

Example:
--------
--------

.. code-block:: lua

   local ikNames = hero:getIKConstraintNames()
   for i, name in ipairs(ikNames) do
       print("IK Constraint name:", name)
   end