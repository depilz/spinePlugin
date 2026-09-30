===================================
skeleton:addEmptyAnimation()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setEmptyAnimation`

Overview:
.........

Queues an empty animation after the current one, fading out over
`mixDuration` (ms) and starting after `delay` (ms).


Syntax:
--------

.. fragment: syntax line; trackIndex, mixDuration and delay are placeholders
.. code-block:: lua

   local trackEntry = skeleton:addEmptyAnimation(trackIndex, mixDuration, delay)

- ``trackIndex`` *(required)*:
    ``number`` – The track index to queue the empty animation.
- ``mixDuration`` *(required)*:
    ``number`` – The duration of the fade-out, in milliseconds.
- ``delay`` *(required)*:
    ``number`` – The delay in milliseconds before starting, as for :doc:`addAnimation`. Omitting it raises.

Return value:
-------------

- ``trackEntry`` – The :doc:`trackEntry/index` of the queued empty animation.

Example:
--------

.. code-block:: lua

   spineboy:setAnimation(1, "shoot", false)
   spineboy:addEmptyAnimation(1, 300, 100)  -- fade out 0.3s, start after 0.1s