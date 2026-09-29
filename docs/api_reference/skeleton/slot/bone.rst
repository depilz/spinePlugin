===================================
slot.bone
===================================

| **Type:** :doc:`bone <../bone/index>` (read-only)
| **See also:** :doc:`index`

Overview:
.........
--------

The :doc:`../bone/index` object to which this slot is attached. You can access bone properties
like `bone.x`, `bone.rotation`, etc., to see how the bone transforms this slot.

Example:
--------
--------

.. code-block:: lua

   local slot = hero.slots[2]
   local parentBone = slot.bone
   print("Slot belongs to bone:", parentBone.name)