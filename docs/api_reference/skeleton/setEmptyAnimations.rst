===================================
skeleton:setEmptyAnimations()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setEmptyAnimation`, :doc:`addEmptyAnimation`

Overview:
.........

Sets an empty animation on every active track and mixes to setup pose over the given duration.

Syntax:
--------

.. code-block:: lua

   skeleton:setEmptyAnimations(mixDuration)

- ``mixDuration`` *(required)*:
    ``number (ms)`` – Mix duration in milliseconds.

Example:
--------

.. code-block:: lua

   -- Smoothly mix out all tracks in 120ms.
   hero:setEmptyAnimations(120)
