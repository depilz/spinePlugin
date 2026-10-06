===================================
skeleton:getCurrentAnimation()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview
--------

Retrieves the name of the animation currently playing on the specified track (default 1).
Returns `nil` if no animation is active.

Syntax
------

.. fragment: syntax line; the brackets mark trackIndex as optional
.. code-block:: lua

   local animName = skeleton:getCurrentAnimation([trackIndex])

Parameters
----------

- ``trackIndex`` *(optional)*:
    ``number`` – The track index to query. Defaults to ``1``.

Return value
------------

- ``string or nil`` – The current animation name, or `nil` if none.

Example
-------

.. code-block:: lua

   print("Track #1 animation:", spineboy:getCurrentAnimation(1))