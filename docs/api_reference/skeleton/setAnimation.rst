===================================
skeleton:setAnimation()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview:
.........

Immediately sets an animation on a given track, overwriting any existing animation on that track.

Syntax:
--------

.. fragment: syntax line; trackIndex, animationName and loop are placeholders
.. code-block:: lua

   local trackEntryOrFalse = skeleton:setAnimation(trackIndex, animationName, loop)

Parameters:
-----------

- **trackIndex** (number) – 1-based track index.
- **animationName** (string) – The name of the animation to set.
- **loop** (boolean) – `true` to loop, `false` otherwise.

Return value:
-------------

- ``trackEntry or false`` – Returns a :doc:`trackEntry/index` on success, otherwise ``false``.

Gotcha:
-------

The returned ``trackEntry`` is meant for immediate configuration and inspection. Do not keep
long-lived references to track entries across clears/replacements.

Example:
--------

.. code-block:: lua

   hero:setAnimation(1, "run", true)