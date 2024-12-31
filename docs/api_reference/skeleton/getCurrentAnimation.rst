===================================
skeleton:getCurrentAnimation([trackIndex])
===================================

| **Type:** Method
| **See also:** :doc:`index`

Overview:
.........
--------

Retrieves the name of the animation currently playing on the specified track (default 1).
Returns `nil` if no animation is active.

Syntax:
--------
--------

.. code-block:: lua

   local animName = skeleton:getCurrentAnimation(trackIndex)

- ``trackIndex`` *(optional)*:
    ``number`` – The track index to query.

Return value:
-------
-------

- ``string or nil`` – The current animation name, or `nil` if none.

Example:
--------
--------

.. code-block:: lua

   print("Track #1 animation:", hero:getCurrentAnimation(1))