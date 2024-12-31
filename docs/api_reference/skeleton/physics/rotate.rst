===================================
physics:rotate(x, y, degrees)
===================================

| **Type:** Method
| **See also:** :doc:`index`, :doc:`translate`

Overview:
.........
--------

Rotates all physics constraints around the point `(x, y)` by the specified `degrees`.

Syntax:
--------
--------

.. code-block:: lua

   physics:rotate(x, y, degrees)

- ``x`` *(required)*:  
    ``number`` – The pivot’s X coordinate.
- ``y`` *(required)*:  
    ``number`` – The pivot’s Y coordinate.
- ``degrees`` *(required)*:  
    ``number`` – Degrees to rotate around the pivot.

Example:
--------
--------

.. code-block:: lua

   -- Rotate the physics system around (100, 200) by 45 degrees
   hero.physics:rotate(100, 200, 45)