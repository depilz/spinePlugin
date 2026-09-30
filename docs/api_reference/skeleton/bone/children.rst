===================================
bone.children
===================================

| **Type:** ``table`` (read-only)
| **See also:** :doc:`index`, :doc:`parent`

Overview:
.........

An array of the bone's child bones, in the skeleton data's order: the bones whose :doc:`parent` is this bone. A bone
without children returns an empty table. Each read builds a new table.

Example:
--------

.. code-block:: lua

   local root = spineboy.bones[1]
   for i, child in ipairs(root.children) do
       print(i, child.name, child.parent.name)
   end
