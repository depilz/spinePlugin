===================================
bone.x
===================================

| **Type:** number (read/write)
| **See also:** :doc:`index`

Overview:
.........
--------

Specifies the bone’s **local X position** relative to its parent bone. Increasing `x` moves
the bone horizontally to the right, while decreasing `x` moves it to the left.

Example:
--------
--------

.. code-block:: lua

   local bone = hero.bones[2]
   -- Move the bone 10 units right
   bone.x = bone.x + 10