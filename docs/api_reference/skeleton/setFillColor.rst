===================================
skeleton:setFillColor()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`/naming`

Overview:
.........

Tints the entire skeleton with a color. You can specify a single grayscale value or separate RGBA
values. The alpha (a) defaults to 1 if omitted.

It writes the same colour as :doc:`fill/color` and :doc:`fill/r`, :doc:`fill/g`, :doc:`fill/b`, :doc:`fill/a`, with one
difference: ``skeleton:setFillColor(v)`` with one argument sets ``r``, ``g`` and ``b`` to ``v`` and ``a`` to ``1``,
while ``skeleton.fill.r = v`` leaves the other components as they were.

Syntax:
--------

.. fragment: syntax line; the brackets mark g, b and a as optional
.. code-block:: lua

   skeleton:setFillColor(r, [g, [b, [a]]])

Example:
---------

.. code-block:: lua

   spineboy:setFillColor(1, 0, 0, 0.5) -- A red tint at 50% opacity