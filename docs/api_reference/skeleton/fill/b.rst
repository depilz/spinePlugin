===================================
skeleton.fill.b
===================================

| **Type:** ``number``
| **See also:** :doc:`../fill`, :doc:`color`, :doc:`../setFillColor`, :doc:`/naming`

Overview:
.........

The **blue** component of the skeleton's fill colour (0–1). The fill colour multiplies the colour of every
attachment the skeleton draws. ``skeleton.fill.b`` reads and writes the same value as
``skeleton.fill.color.b``, and as the matching argument of :doc:`../setFillColor`, one component at a time: the
other components keep their value.

Example:
--------

.. code-block:: lua

   hero.fill.b = 0.5
   print(hero.fill.b, hero.fill.color.b)  -- 0.5  0.5
