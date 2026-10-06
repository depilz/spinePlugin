===================================
skeleton.fill.color
===================================

| **Type:** ``table``
| **See also:** :doc:`../fill`, :doc:`r`, :doc:`g`, :doc:`b`, :doc:`a`, :doc:`../setFillColor`, :doc:`/naming`

Overview
--------

The RGBA components of the skeleton's fill colour: ``{ r = 0–1, g = 0–1, b = 0–1, a = 0–1 }``. The fill colour
multiplies the colour of every attachment the skeleton draws, and is white (``1, 1, 1, 1``) until you change it.

Reading returns a new table; changing a value in that table does not change the skeleton. Writing a table sets the
fill colour: each of ``r``, ``g``, ``b`` and ``a`` that the table holds as a number is set, and the others keep
their value. :doc:`r`, :doc:`g`, :doc:`b` and :doc:`a` read and write the same colour one component at a time, and
:doc:`../setFillColor` sets it with arguments.

Example
-------

.. code-block:: lua

   local c = spineboy.fill.color
   print(c.r, c.g, c.b, c.a)  -- 1  1  1  1

   spineboy.fill.color = { g = 0.5, b = 0.5 }  -- a red tint; r and a keep their value
