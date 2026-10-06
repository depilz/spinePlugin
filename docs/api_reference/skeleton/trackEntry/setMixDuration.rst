===================================
trackEntry:setMixDuration()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`mixDuration`, :doc:`delay`

Overview
--------

Sets ``mixDuration`` (and optionally ``delay``) in milliseconds on this track entry.
Use the 2-argument form when a queued entry was added with ``delay <= 0`` and you later
change mix duration, so delay is recomputed consistently.

Syntax
------

.. fragment: syntax lines; trackEntry, mixDurationMs and delayMs are placeholders
.. code-block:: lua

   trackEntry:setMixDuration(mixDurationMs)
   trackEntry:setMixDuration(mixDurationMs, delayMs)

Parameters
----------

- ``mixDurationMs`` *(required)*:
    ``number`` – The mix duration in milliseconds.
- ``delayMs`` *(optional)*:
    ``number`` – The entry's delay in milliseconds. It has no default: omitted or ``nil``, the entry's delay
    is left unchanged. Greater than ``0``, it becomes the delay. ``0`` or less, the delay is recomputed so the
    mix ends when the previous entry completes, and a negative value makes it end that much earlier (never
    below ``0``).

Example
-------

.. code-block:: lua

   local entry = spineboy:addAnimation(1, "run", true, 0)
   if entry then
       entry:setMixDuration(120, 0)
   end
