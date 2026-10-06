===================================
skeleton.fill.effect.name
===================================

| **Type:** ``string``
| **See also:** :doc:`../effect`

Overview
--------

The name of the skeleton's shader effect, for example ``"filter.desaturate"``: the name last written to
:doc:`../effect` or to ``effect.name``. Writing it changes the effect on every mesh of the skeleton, like writing
``skeleton.fill.effect``; write the effect's attributes again after changing it.

Example
-------

.. code-block:: lua

   spineboy.fill.effect = "filter.desaturate"
   print(spineboy.fill.effect.name)  -- filter.desaturate

   spineboy.fill.effect.name = "filter.blur"
   print(spineboy.fill.effect.name)  -- filter.blur
