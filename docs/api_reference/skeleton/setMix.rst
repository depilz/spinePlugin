===================================
skeleton:setMix(from, to, mix)
===================================

| **Type:** Method
| **See also:** :doc:`index`, :doc:`setDefaultMix`

Overview:
.........
---------

Defines a **custom** mix duration (in ms) when transitioning from one animation to
another by name. This overrides the default mix for that specific pair.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:setMix(fromAnim, toAnim, mix)

- ``fromAnim`` *(required)*:
    ``string`` – The name of the animation to transition from.
- ``toAnim`` *(required)*:
    ``string`` – The name of the animation to transition to.
- ``mix`` *(required)*:
    ``number`` – The mix duration in milliseconds.

Example:
--------
--------

.. code-block:: lua

   hero:setMix("walk", "run", 250)   -- 0.25s transitions from "walk" to "run"
   hero:setMix("run", "jump", 150)