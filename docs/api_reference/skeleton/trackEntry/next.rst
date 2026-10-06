===================================
trackEntry.next
===================================

| **Type:** ``trackEntry`` or ``nil`` (read-only)
| **See also:** :doc:`index`

Overview
--------

The next queued entry on the same track, or ``nil`` if this is the tail of the queue.

Example
-------

.. code-block:: lua

   local current = spineboy:getTrackEntry(1)
   if current and current.next then
       print("Next animation:", current.next.animation)
   end
