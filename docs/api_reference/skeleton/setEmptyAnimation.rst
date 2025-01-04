===================================
skeleton:setEmptyAnimation()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`addEmptyAnimation`

Overview:
.........
--------

Sets an empty animation for a track, discarding any queued animations, and sets the track entry's mixDuration.
An empty animation has no timelines and serves as a placeholder for mixing in or out.

Mixing out is done by setting an empty animation with a mix duration using either :doc:`setEmptyAnimation`, 
:doc:`setEmptyAnimations`, or :doc:`addEmptyAnimation`. Mixing to an empty animation causes the previous animation 
to be applied less and less over the mix duration. Properties keyed in the previous animation transition to 
the value from lower tracks or to the setup pose value if no lower tracks key the property. A mix duration 
of 0 still mixes out over one frame.

Mixing in is done by first setting an empty animation, then adding an animation using :doc:`addAnimation` with the 
desired delay (an empty animation has a duration of 0) and on the returned track entry, set the setMixDuration.
Mixing from an empty animation causes the new animation to be applied more and more over the mix duration. 
Properties keyed in the new animation transition from the value from lower tracks or from the setup pose value 
if no lower tracks key the property to the value keyed in the new animation.


Syntax:
--------
--------

.. code-block:: lua

   skeleton:setEmptyAnimation(trackIndex, mixDuration)

- ``trackIndex`` *(required)*:
    ``number`` – The track index to fade out.
- ``mixDuration`` *(required)*:
    ``number (ms)`` – The duration of the fade-out.

Example:
--------
--------

.. code-block:: lua

   hero:setEmptyAnimation(1, 500)  -- fade out track #1 over 0.5s