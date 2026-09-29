===================================
skeleton:getSlot()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`findSlot`

Overview:
.........

Returns a **Slot** userdata for the specified slot name, or raises ``Slot not found: <name>`` if there is
none. Use :doc:`findSlot` to get ``nil`` instead.

Syntax:
--------

.. code-block:: lua

   local slot = skeleton:getSlot(slotName)

- ``slotName`` *(required)*:
    ``string`` – The name of the slot to search for.

Example:
--------

.. code-block:: lua

   local swordSlot = hero:getSlot("swordHand")
   print("Got slot:", swordSlot.name)