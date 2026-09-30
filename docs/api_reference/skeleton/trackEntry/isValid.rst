===================================
trackEntry.isValid
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`, :doc:`../../../lifecycle`

Overview:
.........

``true`` while the entry is still owned by the skeleton's animation state. It becomes ``false`` once the
entry has finished and been returned to the pool, or once its skeleton has been removed.

``isValid`` is the only key you can read on an invalid entry. Any other key raises
``Track entry is no longer valid (finished or disposed); check entry.isValid``, or
``Track entry belongs to a removed skeleton`` when the skeleton was removed.

Example:
--------

.. code-block:: lua

   local entry = spineboy:setAnimation(1, "shoot", false)

   -- later, maybe several frames after the animation ended
   if entry.isValid then
       entry.timeScale = 2
   end
