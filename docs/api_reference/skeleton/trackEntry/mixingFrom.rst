===================================
trackEntry.mixingFrom
===================================

| **Type:** ``trackEntry`` or ``nil`` (read-only)
| **See also:** :doc:`index`, :doc:`mixingTo`

Overview:
.........

During blending, this points to the entry being mixed out into the current entry.

Example:
--------

.. code-block:: lua

   local entry = spineboy:getTrackEntry(1)
   if entry and entry.mixingFrom then
       print("Mixing from:", entry.mixingFrom.animation)
   end
