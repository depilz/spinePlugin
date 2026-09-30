===================================
slider.mix
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`time`

Overview:
.........

How strongly the slider's animation is applied, from ``0.0`` (no effect) to ``1.0`` (fully applied). Set
``mix = 0`` to stop the slider: it no longer poses the skeleton until ``mix`` is above ``0`` again. Writing ``mix``
keeps a driving bone (see :doc:`boneDriven`).

An animation that keys this slider's mix sets ``mix`` again every time it is applied. A value that is not a number
raises.

Example:
--------

.. code-block:: lua

   local diamond = spine.create(spine.loadSkeletonData("diamond.skel", spine.loadAtlas("diamond.atlas")))
   diamond.sliders.rotation.mix = 0.5  -- Half the slider's influence
