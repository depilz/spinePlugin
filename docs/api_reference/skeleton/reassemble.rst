===================================
skeleton:reassemble()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`split`

Overview:
.........
--------

**Reassembles** a skeleton that was previously :doc:`split <split>`. This will reattach 
the split slots to the skeleton, effectively undoing the split operation.

After the operation, the split group will be removed.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:reassemble()

Example:
--------
--------

.. code-block:: lua

    local splitGroup = skeleton:split({"slot1", "slot2", "slot3"})
    skeleton:reassemble()