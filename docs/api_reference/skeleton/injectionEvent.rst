===================================
injectionEvent
===================================

| **Type:** ``table``
| **See also:** :doc:`index`, :doc:`inject`

Overview:
.........
---------

The **injectionEvent** is triggered on every slot transform update when a display object is 
injected into a Spine slot. You can listen for this event by passing a listener
function to the :doc:`inject` function.


Properties:
-----------
-----------

- **event.slotName**
    ``string`` – The slot name.
- **event.x**
    ``number`` – The x-coordinate of the slot.
- **event.y**
    ``number`` – The y-coordinate of the slot.
- **event.rotation**
    ``number`` – The rotation of the slot.
- **event.xScale**
    ``number`` – The x-scale of the slot.
- **event.yScale**
    ``number`` – The y-scale of the slot.
- **event.alpha**
    ``number`` – The alpha of the slot.


Example:
--------
--------

.. code-block:: lua

    local function listener(event)
        print("Slot:", event.slot)
        print("Position:", event.x, event.y)
        print("Rotation:", event.rotation)
        print("Scale:", event.xScale, event.yScale)
        print("Alpha:", event.alpha)
    end

    skeleton:inject(displayObject, "slotName", listener)
