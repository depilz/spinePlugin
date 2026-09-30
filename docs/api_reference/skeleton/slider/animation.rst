===================================
slider.animation
===================================

| **Type:** ``string`` (read-only)
| **See also:** :doc:`index`, :doc:`duration`, :doc:`time`

Overview:
.........

The name of the animation this slider applies, as set up in the Spine editor. The slider applies it at its own
:doc:`time`, whatever the skeleton's tracks play.

Example:
--------

.. code-block:: lua

   local diamond = spine.create(spine.loadSkeletonData("diamond.skel", spine.loadAtlas("diamond.atlas")))
   print("The slider plays", diamond.sliders.rotation.animation)
