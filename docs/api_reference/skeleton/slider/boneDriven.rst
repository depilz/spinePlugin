===================================
slider.boneDriven
===================================

| **Type:** ``boolean`` (read-only)
| **See also:** :doc:`index`, :doc:`time`

Overview:
.........

``true`` when a bone drives the slider's :doc:`time`: each update sets the time from that bone's transform, as set up
in the Spine editor. ``false`` when the slider has no bone, or once a :doc:`time` write took the slider from its bone,
which cannot be undone.

Example:
--------

.. code-block:: lua

   local diamond = spine.create(spine.loadSkeletonData("diamond.skel", spine.loadAtlas("diamond.atlas")))
   local slider = diamond.sliders.rotation
   print(slider.boneDriven)  -- true: a bone drives the diamond's slider
   slider.time = 0
   print(slider.boneDriven)  -- false from now on
