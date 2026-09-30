===================================
slider.duration
===================================

| **Type:** ``number`` (read-only)
| **See also:** :doc:`index`, :doc:`time`, :doc:`animation`

Overview:
.........

The duration, in seconds, of the slider's :doc:`animation`: the range of :doc:`time` that shows every frame of it.

Example:
--------

.. code-block:: lua

   local diamond = spine.create(spine.loadSkeletonData("diamond.skel", spine.loadAtlas("diamond.atlas")))
   local slider = diamond.sliders.rotation
   slider.time = slider.duration  -- The animation's last frame
