===================================
trackEntry.mixInterpolation
===================================

| **Type:** ``string``
| **See also:** :doc:`index`, :doc:`mixDuration`, :doc:`additive`

Overview
--------

How this entry's mix from the previous entry progresses over its :doc:`mixDuration`. It is one of these names:

- ``"linear"``: at a constant rate (a new entry's value).
- ``"smooth"``: slow at the start and at the end.
- ``"slowFast"``: slow at the start, fast at the end.
- ``"fastSlow"``: fast at the start, slow at the end.
- ``"circle"``: along a circular curve, slow at the start and at the end.

Writing any other value, including ``nil`` or a non-string, raises an error that lists the five names.
Setting it does not change :doc:`mixDuration`; the mix takes as long as before.

Example
-------

.. code-block:: lua

   -- Mix from walk to run over 400 ms, easing in and out
   spineboy:setAnimation(1, "walk", true)
   local run = spineboy:setAnimation(1, "run", true)
   run.mixDuration = 400
   run.mixInterpolation = "smooth"
   print("run mixes in with:", run.mixInterpolation)
