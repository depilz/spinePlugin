===================================
skeleton:findAnimation()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`

Overview:
.........
--------

Checks if an animation with the given name exists in the skeleton’s data.

Syntax:
--------
--------

.. code-block:: lua

   local exists = skeleton:findAnimation(animationName)

- ``animationName`` *(required)*:
    ``string`` – Name of the animation to check.


Return value:
-------
-------

- ``boolean`` – `true` if animation is found, `false` otherwise.

Example:
--------
--------

.. code-block:: lua

   local canDance = hero:findAnimation("dance")
   if canDance then
       hero:setAnimation(1, "dance", true)
   end