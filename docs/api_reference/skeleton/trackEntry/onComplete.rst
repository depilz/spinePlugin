===================================
trackEntry.onComplete
===================================

| **Type:** ``function`` or ``nil``
| **See also:** :doc:`index`, :doc:`../../spine/event`, :doc:`isValid`

Overview
--------

A function called with the event table every time **this** entry completes: at the end of every loop of a looping
entry, once for a non-looping one. It receives the same ``completed`` :doc:`../../spine/event` table as the other
listeners, and runs before them: before the listener passed to :doc:`../../spine/create` and before the ``"spine"``
listeners added with ``skeleton:addEventListener``.

Set it to ``nil`` to clear it. Any other value than a function or ``nil`` raises an error.

- It fires only for ``completed``; the entry's other phases go to the other listeners only.
- It never fires after the skeleton was removed. If it removes the skeleton, the other listeners do not get that
  event.
- The function is released when the entry is disposed or the skeleton is freed. An entry that the animation state
  reuses from its pool starts without one.
- Reading or writing it on an entry that is no longer valid raises, like every other key (see :doc:`isValid`).
- An error inside it is reported like any other listener error; the other listeners and the next events still run.

Example
-------

.. code-block:: lua

   local entry = spineboy:setAnimation(1, "shoot", false)
   entry.onComplete = function(event)
       print("Shoot completed on track", event.trackIndex)
       spineboy:setAnimation(1, "idle", true)
   end
