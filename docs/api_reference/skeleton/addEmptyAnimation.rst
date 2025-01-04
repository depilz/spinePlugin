===================================
skeleton:addEmptyAnimation()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setEmptyAnimation`

Overview:
.........
--------

Queues an empty animation after the current one finishes, fading out over
`mixDuration` (ms) and starting after an optional `delay`.


Syntax:
--------
--------

.. code-block:: lua

   skeleton:addEmptyAnimation(trackIndex, mixDuration, delay)

- ``trackIndex`` *(required)*:
    ``number`` – The track index to queue the empty animation.
- ``mixDuration`` *(required)*:
    ``number`` – The duration of the fade-out.
- ``delay`` *(optional)*:
    ``number`` – Additional delay in milliseconds before starting.

Example:
--------
--------

.. code-block:: lua

   hero:setAnimation(1, "attack", false)
   hero:addEmptyAnimation(1, 300, 100)  -- fade out 0.3s, start after 0.1s