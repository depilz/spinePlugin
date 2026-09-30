===================================
trackEntry.mixDuration
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`mixTime`

Overview:
.........

Mix duration in milliseconds for this entry. This controls how long the transition into this
entry blends from the previous entry.

Example:
--------

.. code-block:: lua

   local entry = spineboy:setAnimation(1, "idle", true)
   if entry then
       entry.mixDuration = 120
   end
