===================================
skeleton:setFillColor(r, g, b, a)
===================================

| **Type:** Method
| **See also:** :doc:`index`

Overview:
.........
---------

Tints the entire skeleton with a color. You can specify a single grayscale value or separate RGBA
values. The alpha (a) defaults to 1 if omitted.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:setFillColor(r, [g, [b, [a]]])

Example:
---------
---------

.. code-block:: lua

   hero:setFillColor(1, 0, 0, 0.5) -- A red tint at 50% opacity