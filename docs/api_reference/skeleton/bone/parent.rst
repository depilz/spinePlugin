===================================
bone.parent
===================================

| **Type:** :doc:`bone <index>` | ``nil`` (read-only)
| **See also:** :doc:`../bones`

Overview:
.........
--------

Returns the **parent** bone, or ``nil`` if this bone has no parent (i.e., it's a root bone).

Example:
--------
--------

.. code-block:: lua

   local childBone = hero.bones[5]
   local parentBone = childBone.parent
   if parentBone then
       print("Parent bone name:", parentBone.name)
   else
       print("This is the root bone!")
   end