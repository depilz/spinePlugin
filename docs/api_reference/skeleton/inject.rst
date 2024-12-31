===================================
skeleton:inject(slotName, object, listener)
===================================

| **Type:** Function
| **See also:** :doc:`index`, :doc:`eject`

Overview:
.........
--------

**Injects** a Solar2D display object into a given slot’s transform. This lets you attach
custom display objects (e.g., images, effects) to a Spine slot, with a
`listener` function that let's you track the slot's transform updates.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:inject(slotName, object, listener)

- ``slotName`` *(required)*:
    ``string`` – The slot to which the object will attach.
- ``object`` *(required)*:
    ``displayObject`` – The Solar2D display object to attach.
- ``listener`` *(required)*:
    ``function`` – A callback invoked on every slot transform update.

Example:
--------
--------

.. code-block:: lua

   local function onUpdateSlot(event)
       print("Slot update:", event.slot, "X:", event.x, "Y:", event.y)
   end

   hero:inject("hand", mySwordObject, onUpdateSlot)