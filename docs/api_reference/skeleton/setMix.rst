===================================
skeleton:setMix()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setDefaultMix`

Overview
--------

Defines a **custom** mix duration (in ms) when transitioning from one animation to
another by name. This overrides the default mix for that specific pair.

Syntax
------

.. fragment: syntax line; fromAnim, toAnim and mix are placeholders
.. code-block:: lua

   skeleton:setMix(fromAnim, toAnim, mix)

Parameters
----------

- ``fromAnim`` *(required)*:
    ``string`` – The name of the animation to transition from.
- ``toAnim`` *(required)*:
    ``string`` – The name of the animation to transition to.
- ``mix`` *(required)*:
    ``number`` – The mix duration in milliseconds.

Example
-------

.. code-block:: lua

   spineboy:setMix("walk", "run", 250)  -- 0.25s transitions from "walk" to "run"
   spineboy:setMix("run", "jump", 150)