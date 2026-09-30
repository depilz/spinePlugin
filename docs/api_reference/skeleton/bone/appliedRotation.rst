===================================
bone.appliedRotation
===================================

| **Type:** ``number`` (read/write)
| **See also:** :doc:`index`

Overview:
.........

Reflects the rotation that Spine calculates for this bone during animation. Setting
`appliedRotation` directly can override the animation’s rotation if you want manual control.

Example:
--------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local bone = spineboy.bones[2]
   print("Applied rotation before override:", bone.appliedRotation)
   bone.appliedRotation = 30