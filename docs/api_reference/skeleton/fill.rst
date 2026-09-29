===================================
skeleton.fill
===================================

| **Type:** ``userdata``
| **See also:** :doc:`index`, :doc:`setFillColor`, :doc:`/naming`

Overview:
.........

``skeleton.fill`` is the skeleton's fill: the colour that multiplies every attachment the skeleton draws, and the
Solar2D shader effect the skeleton is drawn with. Each read returns a new object for the same skeleton. Reading a key
the fill does not have returns ``nil``; writing one does nothing.

Properties:
-----------

.. toctree::
   :maxdepth: 1

   fill/color
   fill/r
   fill/g
   fill/b
   fill/a
   fill/effect

Example:
--------

.. code-block:: lua

   local fill = hero.fill
   fill.color = { r = 1, g = 0.5, b = 0.5 }
   fill.effect = "filter.desaturate"
   print(fill.r, fill.effect.name)  -- 1  filter.desaturate
