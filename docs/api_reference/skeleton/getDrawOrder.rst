===================================
skeleton:getDrawOrder()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview:
.........
---------

Returns a table of **all slot names** in the current draw order of this skeleton, as strings.


Syntax:
--------
--------

.. code-block:: lua

   local slotNames = skeleton:getDrawOrder()

Return value:
-------------
-------------

``table`` – A table of strings, each representing a slot name.


Example:
--------
--------

.. code-block:: lua

    local drawOrder = skeleton:getDrawOrder()
    for i, name in ipairs(drawOrder) do
         print("Slot name:", name)
    end