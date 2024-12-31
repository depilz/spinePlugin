===================================
skeleton:getSlot(slotName)
===================================

| **Type:** Method
| **See also:** :doc:`index`, :doc:`findSlot`

Overview:
.........
--------

Returns a **Slot** userdata for the specified slot name, or throws an error if not found.

Syntax:
--------
--------

.. code-block:: lua

   local slot = skeleton:getSlot(slotName)

- ``slotName`` *(required)*:
    ``string`` – The name of the slot to search for.

Example:
--------
--------

.. code-block:: lua

   local swordSlot = hero:getSlot("swordHand")
   if swordSlot then
       print("Got slot:", swordSlot.name)
   end