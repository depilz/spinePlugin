===================================
slider.loop
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`, :doc:`time`, :doc:`boneDriven`

Overview:
.........

``true`` when the slider's animation loops, as set up in the Spine editor: a :doc:`time` past the animation's
:doc:`duration` wraps around to its start, and a bone-driven time wraps into ``duration``. When ``false``, a time
past the end holds the animation's last frame.

Example:
--------

.. code-block:: lua

   local diamond = spine.create(spine.loadSkeletonData("diamond.skel", spine.loadAtlas("diamond.atlas")))
   print("The slider loops:", diamond.sliders.rotation.loop)
