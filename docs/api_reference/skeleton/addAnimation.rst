===================================
skeleton:addAnimation()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setAnimation`

Overview:
.........

Queues an animation to play **after** the current one completes on the specified track,
optionally waiting a certain delay before starting.

If no animation is currently playing on the track, the queued animation will start immediately.

Syntax:
--------

.. code-block:: lua

   local trackEntryOrFalse = skeleton:addAnimation(trackIndex, animationName, loop, delay)

- ``trackIndex`` *(required)*:
    ``number`` – The 1-based track index to queue the animation.
- ``animationName`` *(required)*:
    ``string`` – Name of the animation.
- ``loop`` *(required)*:
    ``boolean`` – Loop or not.
- ``delay`` *(required)*:
    ``number (ms)`` – Additional delay in milliseconds before starting.

Return value:
-------------

- ``trackEntry or false`` – Returns a :doc:`trackEntry/index` on success, otherwise ``false``.

Gotcha:
-------

The returned ``trackEntry`` is intended for immediate setup (for example ``mixDuration``).
Avoid holding references for long periods while the queue continues to change.

Example:
--------

.. code-block:: lua

   -- Start "walk" now, queue "run" afterward, delayed by 200ms
   hero:setAnimation(1, "walk", true)
   hero:addAnimation(1, "run", true, 200)