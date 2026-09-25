===================================
trackEntry.mixingTo
===================================

| **Type:** ``trackEntry`` or ``nil`` (read-only)
| **See also:** :doc:`index`, :doc:`mixingFrom`

Overview:
.........

During blending, this points to the entry being mixed into from the current entry.

Example:
--------

.. code-block:: lua

   local entry = hero:getTrackEntry(1)
   if entry and entry.mixingTo then
       print("Mixing to:", entry.mixingTo.animation)
   end
