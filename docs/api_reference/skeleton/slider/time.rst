===================================
slider.time
===================================

| **Type:** ``number``
| **See also:** :doc:`index`, :doc:`boneDriven`, :doc:`duration`, :doc:`mix`

Overview
--------

The time, in seconds, at which the slider applies its :doc:`animation`. The skeleton shows a new time at the next
``updateState`` or draw.

When a bone drives the slider (:doc:`boneDriven` is ``true``), each update sets the time from that bone, and ``time``
reads the value of the last update.

.. warning::

   Writing ``time`` on a bone-driven slider takes the slider from its bone **for good**: :doc:`boneDriven` becomes
   ``false``, moving the bone no longer changes the time, and there is no way to give the bone back to the slider.
   Only this skeleton instance is affected; other skeletons created from the same skeleton data keep their bone.

An animation that keys this slider's time sets ``time`` again every time it is applied. A value that is not a number
raises.

Example
-------

.. code-block:: lua

   local diamond = spine.create(spine.loadSkeletonData("diamond.skel", spine.loadAtlas("diamond.atlas")))
   local slider = diamond.sliders.rotation

   -- Show the slider's animation halfway through
   slider.time = slider.duration / 2
