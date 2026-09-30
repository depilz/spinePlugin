===================================
slider
===================================

| **Type:** ``userdata``
| **See also:** :doc:`../sliders`, :doc:`../index`

Overview:
..........

A **Slider** object is a Spine 4.3 slider constraint of a skeleton. A slider applies one animation of the skeleton
at a time of its own instead of a track's time: set :doc:`time` from Lua to scrub the animation, or let a bone drive
it (:doc:`boneDriven`), as set up in the Spine editor. :doc:`mix` blends the slider's animation over the pose.

Below is a list of all properties on a Slider. ``time`` and ``mix`` are **read/write**; writing any other key listed
here raises ``SpineSlider: property '<key>' is read-only``, and writing a key that is not listed raises
``SpineSlider: unknown property '<key>'``.

Two Slider objects compare equal with ``==`` when they are the same slider of the same skeleton instance.
Reading, writing or comparing a slider of a removed skeleton raises ``Slider belongs to a removed skeleton``
(see :doc:`/lifecycle`).

Properties:
-----------

.. toctree::
   :maxdepth: 1

   name
   animation
   time
   mix
   duration
   loop
   boneDriven
