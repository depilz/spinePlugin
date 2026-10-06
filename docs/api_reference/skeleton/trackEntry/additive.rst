===================================
trackEntry.additive
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`, :doc:`alpha`, :doc:`mixInterpolation`

Overview
--------

When ``true``, this entry's animation adds its values to the pose of the tracks below it instead of replacing
them. A new entry is not additive (``false``). Set it right after ``setAnimation`` or ``addAnimation``, before the
next ``updateState``.

It has no effect on the first track (track 1) while that entry's :doc:`alpha` is 1: that entry always poses the
skeleton from its setup pose, as Spine does.

Example
-------

.. code-block:: lua

   -- Walk on track 1, and add the aim on top of it on track 2
   spineboy:setAnimation(1, "walk", true)
   local aim = spineboy:setAnimation(2, "aim", true)
   aim.additive = true
   print("aim is additive:", aim.additive)
