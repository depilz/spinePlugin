===================================
skeleton:findSlot()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getSlot`

Overview:
.........

Returns the **Slot** object with the name `slotName`, or ``nil`` if the skeleton has no such slot.

Syntax:
--------

.. fragment: syntax line; slotName is a placeholder
.. code-block:: lua

   local slot = skeleton:findSlot(slotName)

- ``slotName`` *(required)*:
    ``string`` – The name of the slot to search for.

Return value:
-------------

``Slot`` or ``nil`` – The slot, or ``nil`` if it does not exist. Use :doc:`getSlot` to raise instead.

Example:
........

.. code-block:: lua

   local slot = spineboy:findSlot("backpack")
   if slot then
       print("Slot 'backpack' exists:", slot.name)
   else
       print("Slot 'backpack' not found.")
   end
