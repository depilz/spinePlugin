===================================
slot.attachment
===================================

| **Type:** string (read/write) or nil
| **See also:** :doc:`index`

Overview:
.........
--------

Indicates the **name** of the current attachment displayed by this slot.
Set `nil` to clear, or any valid attachment name to switch images/meshes.
Reading returns the attachment name or `nil` if no attachment is set.

Example:
--------
--------

.. code-block:: lua

   local slot = hero.slots[1]
   print("Current attachment name:", slot.attachment)
   slot.attachment = "swordMesh"
   ...
   slot.attachment = nil  -- remove the attachment