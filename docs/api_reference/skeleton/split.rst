===================================
skeleton:split()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`reassemble`

Overview:
.........

**Splits** a skeleton into a display group containing the slots specified in the table. This lets
you manipulate the given slots separately from the rest of the skeleton, being useful for some 3D effects.

If you try re-splitting a skeleton, it will overwrite the list of slots, but keep the group intact.

To reassemble the skeleton, use the :doc:`reassemble <reassemble>` function.

:doc:`hitTest` keeps testing split slots in the skeleton object's space, so they hit correctly only while the split
group has the same content transform as the skeleton object.

.. image:: split.gif
    :align: center

Syntax:
--------

.. fragment: syntax line; slotNames is a placeholder
.. code-block:: lua

   local splitGroup = skeleton:split(slotNames)

- ``slotNames`` *(required)*:
    ``table`` – A table containing the names of the slots to split.

Return Value:
-------------

- ``splitGroup``:
    ``displayGroup`` – A display group containing the display objects that were split from the skeleton.

Example:
--------

.. code-block:: lua

    local sceneGroup = display.newGroup()
    local splitGroup = skeleton:split({"upper-arm1", "forearm1", "hand1"})

    -- Move the split group
    splitGroup.x = 100
    splitGroup.y = 100

    -- Insert the split group into the scene
    sceneGroup:insert(splitGroup)