===================================
skeleton:setDefaultMix()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setMix`

Overview:
.........
---------

Sets the **default** mix duration (in milliseconds) for transitions between animations
that don’t have a specific mix time configured.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:setDefaultMix(mix)

- ``mix`` *(required)*:
    ``number`` – The default mix duration in milliseconds.

Example:
--------
--------

.. code-block:: lua

   hero:setDefaultMix(300)  -- 0.3 second default transitions