===================================
skeleton:getIkConstraint()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getIKConstraintNames`, :doc:`ikConstraint/index`, :doc:`/naming`

Overview:
.........

Retrieves the :doc:`ikConstraint/index` with the specified IK constraint name. An unknown name raises
``IKConstraint not found: <name>``; use :doc:`getIKConstraintNames` to check the names first.
``skeleton:getIKConstraint()`` is an alias of this method: it is the same function, and both names stay supported
(see :doc:`/naming`).

Syntax:
--------

.. fragment: syntax line; ikConstraintName is a placeholder
.. code-block:: lua

   local ikObj = skeleton:getIkConstraint(ikConstraintName)

- ``ikConstraintName`` *(required)*:
    ``string`` – The name of the IK constraint to search for.

Return value:
-------------

``IKConstraint`` – The IK constraint object. See :doc:`ikConstraint/index` for more information.

Example:
--------

.. code-block:: lua

   local legIK = spineboy:getIkConstraint("front-leg-ik")
   print("Found IK constraint:", legIK.name)

   -- An unknown name raises: check the names first, or catch the error
   local ok = pcall(spineboy.getIkConstraint, spineboy, "armIK")
   print("armIK exists:", ok)
