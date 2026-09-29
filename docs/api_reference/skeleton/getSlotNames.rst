===================================
skeleton:getSlotNames()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview:
.........
---------

Returns a table of **all slot names** in this skeleton, as strings.

Syntax:
--------
--------

.. code-block:: lua

   local names = skeleton:getSlotNames()

Return value:
-------------
-------------

``table`` – A table of strings, each representing a slot name.


Example:
--------
--------

.. code-block:: lua

   local slotNames = hero:getSlotNames()
   for i, name in ipairs(slotNames) do
       print("Slot name:", name)
   end