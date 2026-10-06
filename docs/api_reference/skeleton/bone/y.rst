===================================
bone.y
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

Specifies the bone’s **local Y position** relative to its parent, along the parent bone's Y axis. As in the
Spine editor, increasing `y` moves the bone up and decreasing it moves the bone down (for a parent that is not
rotated). The bone's :doc:`worldY` is in skeleton space, where y grows downward, so it decreases when `y` increases.

Example
-------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local bone = spineboy.bones[3]
   bone.y = bone.y + 20  -- Moves the bone 20 units up