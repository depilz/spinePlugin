===================================
bone.y
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview:
.........
--------

Specifies the bone’s **local Y position** relative to its parent. Increasing `y` moves the 
bone downward, while decreasing `y` moves it upward.

Example:
........
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local bone = hero.bones[3]
   bone.y = bone.y - 20  -- Moves the bone 20 units up