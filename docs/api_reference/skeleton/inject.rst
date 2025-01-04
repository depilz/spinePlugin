===================================
skeleton:inject()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`injectionEvent`, :doc:`eject`

Overview:
.........
--------

**Injects** a Solar2D display object into a given slot’s transform. This lets you attach
custom display objects (e.g., images, effects) to a Spine slot, with a
:doc:`injectionEvent` function that let's you track the slot's transform updates.

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
    ``function`` – A callback invoked on every slot transform update. See :doc:`injectionEvent` for more details.

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
