===================================
ikConstraint.stretch
===================================

| **Type:** boolean (read/write)
| **See also:** :doc:`index`

Overview:
.........
--------

When `stretch` is `true`, bones in this IK chain can stretch to match the
distance to the target. This can help avoid dead zones where the chain
is too short or too long for the desired position.

Example:
--------
--------

.. code-block:: lua

   local armIK = hero.ikConstraints[1]
   armIK.stretch = true