===================================
skeleton:getAnimations()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`findAnimation`

Overview:
.........
--------

Returns a table of all animation names defined in the skeleton’s data.

Syntax:
--------
--------

.. code-block:: lua

   local animations = skeleton:getAnimations()

Return value:
-------------
-------------

- ``table`` – A table of strings, each representing an animation name.


Example:
--------
--------

.. code-block:: lua

   local animations = hero:getAnimations()
   for i, anim in ipairs(animations) do
       print("Animation:", anim)
   end