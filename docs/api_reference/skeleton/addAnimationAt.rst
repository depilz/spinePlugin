===================================
skeleton:addAnimationAt()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`addAnimation`, :doc:`trackEntry/index`

Overview:
.........

Queues an animation at an absolute track timeline time (in milliseconds), where ``0`` is the
start of the current track sequence. This is useful when you schedule animation changes from
authored timestamps.

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
