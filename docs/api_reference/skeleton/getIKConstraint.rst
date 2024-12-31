===================================
skeleton:getIKConstraint(ikConstraintName)
===================================

| **Type:** Method
| **See also:** :doc:`index`, :doc:`getIkConstraintNames`, :doc:`ikConstraint/index`

Overview:
.........
---------

Retrieves a :doc:`ikConstraint/index` for the specified IK constraint name or `nil` if not found.

Syntax:
--------
--------

.. code-block:: lua

   local ikObj = skeleton:getIKConstraint(ikConstraintName)

- ``ikConstraintName`` *(required)*:
    ``string`` – The name of the IK constraint to search for.

Return value:
--------
--------

``LuaIKConstraint or nil`` – The IK constraint object, or `nil` if not found. See :doc:`ikconstraint/index` for more information.

Example:
--------
--------

.. code-block:: lua

   local armIK = hero:getIKConstraint("armIK")
   if armIK then
       print("Found IK constraint:", armIK.name)
   end