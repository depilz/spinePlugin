===================================
trackEntry.trackComplete
===================================

| **Type:** ``number`` (read-only)
| **See also:** :doc:`index`, :doc:`trackTime`

Overview
--------

Time in milliseconds at which this entry will complete on its track.

Example
-------

.. code-block:: lua

   local entry = spineboy:getTrackEntry(1)
   if entry then
       print("Completes at:", entry.trackComplete)
   end
