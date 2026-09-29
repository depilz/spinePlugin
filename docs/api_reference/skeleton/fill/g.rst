===================================
skeleton.fill.g
===================================

| **Type:** ``number``
| **See also:** :doc:`../fill`, :doc:`color`, :doc:`../setFillColor`, :doc:`/naming`

Overview:
.........

The **green** component of the skeleton's fill colour (0–1). The fill colour multiplies the colour of every
attachment the skeleton draws. ``skeleton.fill.g`` reads and writes the same value as
``skeleton.fill.color.g``, and as the matching argument of :doc:`../setFillColor`, one component at a time: the
other components keep their value.

Example:
--------

.. code-block:: lua

   hero.fill.g = 0.5
   print(hero.fill.g, hero.fill.color.g)  -- 0.5  0.5
