===================================
skeleton:setAnimation()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview
--------

Immediately sets an animation on a given track, overwriting any existing animation on that track.

Syntax
------

.. fragment: syntax line; trackIndex, animationName and loop are placeholders
.. code-block:: lua

   local trackEntryOrFalse = skeleton:setAnimation(trackIndex, animationName, loop)

Parameters
----------

- ``trackIndex`` *(required)*:
    ``number`` – 1-based track index.
- ``animationName`` *(required)*:
    ``string`` – The name of the animation to set.
- ``loop`` *(optional)*:
    ``boolean`` – ``true`` to loop, ``false`` otherwise. Defaults to ``false``.

Return value
------------

- ``trackEntry or false`` – Returns a :doc:`trackEntry/index` on success, otherwise ``false``.

Example
-------

.. code-block:: lua

   spineboy:setAnimation(1, "run", true)

Notes
-----

The returned ``trackEntry`` is meant for immediate configuration and inspection. Do not keep
long-lived references to track entries across clears/replacements.