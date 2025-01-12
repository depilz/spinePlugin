===================================
skeleton:changeInjectionSlot(object, slotName)
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`inject`

Overview:
.........
--------

**Changes** the slot to which a previously injected Solar2D display object is attached. This 
lets you reassign the slot of an injected object without having to remove and re-inject it.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:changeInjectionSlot(object, slotName)

- ``object`` *(required)*:
    ``displayObject`` – The object to reassign.
- ``slotName`` *(required)*:
    ``string`` – The new slot to which the object will attach.

Example:
--------
--------

.. code-block:: lua

    local function onUpdateHat(event)
        print("Hat position:", event.x, event.y)
    end

    -- Inject an object
    hero:inject(myHatObject, "head", onUpdateHat)
    ...

    -- Later, change the slot of that object
    hero:changeInjectionSlot(myHatObject, "back")
