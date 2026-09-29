===================================
trackEntry.trackIndex
===================================

| **Type:** ``number`` (read-only)
| **See also:** :doc:`index`, :doc:`/naming`

Overview:
.........

The 1-based index of the track the entry plays on: the track number you passed to :doc:`../setAnimation` or
:doc:`../addAnimation`. The listener event of an animation carries the same number as ``event.trackIndex`` (see
:doc:`../../spine/event`).

``entry.index`` is an alias of ``entry.trackIndex``: it reads the same value. Both are read-only: writing either
raises ``SpineTrackEntry: property '<key>' is read-only``, with the key you wrote.

Example:
--------

.. code-block:: lua

   local entry = hero:setAnimation(1, "idle", true)
   print(entry.trackIndex, entry.index)  -- 1  1
