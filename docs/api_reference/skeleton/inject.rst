===================================
skeleton:inject()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`injectionEvent`, :doc:`eject`

Overview:
.........
--------

**Injects** a Solar2D display object on top of a given slot. This lets you attach
custom display objects like images, effects or even another skeleton instance to a slot, with a
:doc:`injectionEvent` function that let's you track the slot's transform updates.

If you try re-inserting the same object, it will overwrite the previous one, but if you only want to
update the slot it is attached to, it is recommended to use the :doc:`changeInjectionSlot <changeInjectionSlot>` function instead.

.. note::

    When an object is removed, it is automatically ejected from the skeleton.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:inject(object, slotName, listener)

- ``object`` *(required)*:
    ``displayObject`` – The Solar2D display object to attach.
- ``slotName`` *(required)*:
    ``string`` – The slot to which the object will attach.
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
