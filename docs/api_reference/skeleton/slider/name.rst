===================================
slider.name
===================================

| **Type:** ``string`` (read-only)
| **See also:** :doc:`index`, :doc:`../sliders`

Overview
--------

The **name** of this slider, as defined in Spine. It is the slider's key in :doc:`../sliders`.

Example
-------

.. code-block:: lua

   local diamond = spine.create(spine.loadSkeletonData("diamond.skel", spine.loadAtlas("diamond.atlas")))
   local slider = diamond.sliders.rotation
   print("Slider name:", slider.name)
