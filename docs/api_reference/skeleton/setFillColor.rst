===================================
skeleton:setFillColor()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`/naming`

Overview
--------

Tints the entire skeleton with a color. You can specify a single grayscale value or separate RGBA
values. The alpha (a) defaults to 1 if omitted.

It writes the same colour as :doc:`fill/color` and :doc:`fill/r`, :doc:`fill/g`, :doc:`fill/b`, :doc:`fill/a`, with one
difference: ``skeleton:setFillColor(v)`` with one argument sets ``r``, ``g`` and ``b`` to ``v`` and ``a`` to ``1``,
while ``skeleton.fill.r = v`` leaves the other components as they were.

Syntax
------

.. fragment: syntax line; the brackets mark g, b and a as optional
.. code-block:: lua

   skeleton:setFillColor(gray, alpha)
   skeleton:setFillColor(r, g, b, a)

Parameters
----------

- ``gray`` *(required)*:
    ``number`` – The gray level, from 0 to 1, used for red, green and blue in the one- and two-argument
    forms.
- ``alpha`` *(optional)*:
    ``number`` – The opacity, from 0 to 1, in the two-argument form. Defaults to ``1``.
- ``r``, ``g``, ``b`` *(required)*:
    ``number`` – The red, green and blue levels, from 0 to 1, in the three- and four-argument forms.
- ``a`` *(optional)*:
    ``number`` – The opacity, from 0 to 1, in the four-argument form. Defaults to ``1``.

Example
-------

.. code-block:: lua

   spineboy:setFillColor(1, 0, 0, 0.5) -- A red tint at 50% opacity