===================================
skeleton:getIkConstraintNames()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getIKConstraint`, :doc:`/naming`

Overview
--------

Returns an array of all IK constraint names in this skeleton's data. The :doc:`ikConstraints` property returns the
IK constraint objects instead. ``skeleton:getIKConstraintNames()`` is an alias of this method: it is the same
function, and both names stay supported (see :doc:`/naming`).

Syntax
------

.. code-block:: lua

   local names = skeleton:getIkConstraintNames()

Example
-------

.. code-block:: lua

   local ikNames = spineboy:getIkConstraintNames()
   for i, name in ipairs(ikNames) do
       print("IK Constraint name:", name)
   end
