===================================
injectionEvent
===================================

| **Type:** ``table``
| **See also:** :doc:`index`, :doc:`inject`, :doc:`/naming`

Overview
--------

The **injectionEvent** is passed to the listener of a display object injected into a Spine slot, every time the
skeleton draws that slot (each :doc:`draw`), and once more with ``isVisible = false`` when the slot stops being drawn.
You listen for this event by passing a listener function to the :doc:`inject` function.

The position, rotation and scale are the slot's bone world transform, in skeleton space: the skeleton group's
coordinates, the ones the injected object lives in. The keys use display object names (``xScale``, ``alpha``, …)
because they are the values you copy to the injected display object; ``event.alpha`` is the animated Spine slot
colour, not :doc:`slot.a <slot/a>` (see :doc:`/naming`).


Properties
----------

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
    ``number`` – The alpha of the slot's Spine color.
- **event.isVisible**
    ``boolean`` – ``true`` while the slot is drawn, ``false`` on the call made when it stops being drawn.
- **event.target**
    ``displayObject`` – The injected object.


Example
-------

.. code-block:: lua

    local displayObject = display.newRect(0, 0, 20, 20)

    local function listener(event)
        print("Slot:", event.slotName)
        print("Position:", event.x, event.y)
        print("Rotation:", event.rotation)
        print("Scale:", event.xScale, event.yScale)
        print("Alpha:", event.alpha)
        print("Visible:", event.isVisible, event.target == displayObject)
    end

    skeleton:inject(displayObject, "gun", listener)
    skeleton:draw()
