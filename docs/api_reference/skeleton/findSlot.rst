===================================
skeleton:findSlot()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview:
.........
--------

Returns a boolean indicating whether a slot with `slotName` exists in the skeleton.

Syntax:
--------
--------

.. code-block:: lua

   local exists = skeleton:findSlot(slotName)

- ``slotName`` *(required)*:
    ``string`` – The name of the slot to search for.

Return value:
-------------
-------------

``boolean`` – `true` if the slot exists, `false` otherwise.

Example:
........
--------

.. code-block:: lua

   if hero:findSlot("backpack") then
       print("Slot 'backpack' exists!")
   else
       print("Slot 'backpack' not found.")
   end