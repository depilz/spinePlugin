===================================
skeleton:addAnimationAt()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`addAnimation`, :doc:`trackEntry/index`

Overview:
.........

Queues an animation at an absolute track timeline time (in milliseconds). This is useful when you schedule
animation changes from authored timestamps.

The time is measured from the start of the entry currently playing on the track, so the origin moves as the queue
advances. On an empty track, the time is measured from now: a positive time first sets an empty animation on the
track, and ``0`` or less plays the animation at once.

Gotchas:
--------

On a track that is playing, a time at or before the start of the last queued entry does not wait for that entry to
complete: the new entry starts on the update right after the last queued entry starts. Queue times in increasing
order to get one entry after the other at their own times.

Syntax:
--------

.. code-block:: lua

   local trackEntryOrFalse = skeleton:addAnimationAt(trackIndex, animationName, loop, startTimeMs)

- ``trackIndex`` *(required)*:
    ``number`` – 1-based track index.
- ``animationName`` *(required)*:
    ``string`` – Name of the animation.
- ``loop`` *(required)*:
    ``boolean`` – Loop or not.
- ``startTimeMs`` *(required)*:
    ``number (ms)`` – Absolute time on the track timeline.

Return value:
-------------

- ``trackEntry or false`` – Returns a :doc:`trackEntry/index` on success, otherwise ``false``.

Example:
--------

.. code-block:: lua

   hero:setAnimation(1, "idle", true)
   hero:addAnimationAt(1, "talk_open", false, 120)
   hero:addAnimationAt(1, "talk_closed", false, 180)
