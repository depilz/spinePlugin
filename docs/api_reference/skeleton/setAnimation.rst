===================================
skeleton:setAnimation(trackIndex, animationName, loop)
===================================

| **Type:** Method
| **See also:** :doc:`skeleton.index`

Overview:
.........
Immediately sets an animation on a given track, overwriting any existing animation on that track.

Syntax:
--------
.. code-block:: lua

   skeleton:setAnimation(trackIndex, animationName, loop)

Parameters:
-----------
- **trackIndex** (number) – 1-based track index.
- **animationName** (string) – The name of the animation to set.
- **loop** (boolean) – `true` to loop, `false` otherwise.

Example:
--------
.. code-block:: lua

   hero:setAnimation(1, "run", true)