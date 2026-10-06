===================================
physics.mix
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`isActive`

Overview
--------

Adjusts the **mix** factor for the physics constraints, determining how much
physics influences the bones versus their original animation or transforms.
Writing ``mix`` sets it on every physics constraint of the skeleton; reading it returns the first
constraint's value.

Set ``mix = 0`` to stop physics: the constraints no longer move their bones until ``mix`` is above ``0``
again. This is the way to turn physics off; :doc:`isActive` is read-only.

.. note::

   An animation that keys a physics constraint's mix sets ``mix`` again every time it is applied, so a
   value written from Lua lasts only until the next update. To keep physics stopped, key its mix to ``0``
   in the animation, or stop playing that animation.

.. note::

   While ``mix`` is ``0`` the simulation does not advance. When ``mix`` goes back above ``0``, physics
   catches up the whole time it was stopped in a single step, which can make the bones jump. To pause
   physics without that catch-up, set the skeleton's :doc:`../physicsTimeScale` to ``0`` instead.

Example
-------

.. code-block:: lua

   -- spineboy has no physics constraints; celestial-circus has
   local circus = spine.create(spine.loadSkeletonData("assets/characters/celestial-circus.json",
                                                      spine.loadAtlas("assets/characters/celestial-circus.atlas")))

   circus.physics.mix = 0.5
   print("Physics mix:", circus.physics.mix)