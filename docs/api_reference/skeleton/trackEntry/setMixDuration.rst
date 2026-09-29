===================================
trackEntry:setMixDuration()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`mixDuration`, :doc:`delay`

Overview:
.........

Sets ``mixDuration`` (and optionally ``delay``) in milliseconds on this track entry.
Use the 2-argument form when a queued entry was added with ``delay <= 0`` and you later
change mix duration, so delay is recomputed consistently.

Syntax:
--------

.. fragment: syntax lines; trackEntry, mixDurationMs and delayMs are placeholders
.. code-block:: lua

   trackEntry:setMixDuration(mixDurationMs)
   trackEntry:setMixDuration(mixDurationMs, delayMs)

Example:
--------

.. code-block:: lua

   local entry = hero:addAnimation(1, "run", true, 0)
   if entry then
       entry:setMixDuration(120, 0)
   end
