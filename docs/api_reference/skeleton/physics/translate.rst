===================================
physics:translate()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`rotate`

Overview:
.........
---------

Translates all physics constraints by the given `(x, y)` offset.


Syntax:
--------
--------

.. code-block:: lua

   physics:translate(x, y)

- ``x`` *(required)*:  
    ``number`` – The horizontal translation offset.
- ``y`` *(required)*:  
    ``number`` – The vertical translation offset.

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local hero = spine.create(skeletonData)

   -- Move physics constraints 10 units right, 20 units up
   hero.physics:translate(10, -20)