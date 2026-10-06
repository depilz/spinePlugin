===================================
skeleton:getSize()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getBounds`

Overview
--------

Returns the current size of the skeleton and the offset from the origin point. The values come from the same
bounds as :doc:`getBounds`, and are current right after :doc:`../spine/create` and after every :doc:`updateState`.

Syntax
------

.. code-block:: lua

   local size = skeleton:getSize()

Return value
------------

``size`` – A table with the following fields:

- ``width``: ``number`` – The width of the skeleton.

- ``height``: ``number`` – The height of the skeleton.

- ``offsetX``: ``number`` – The left edge of the bounds, relative to the origin point. Equal to
  ``getBounds().xMin``.

- ``offsetY``: ``number`` – The top edge of the bounds, relative to the origin point. Equal to
  ``getBounds().yMin``.

``(offsetX, offsetY)`` is the top-left corner of the skeleton in the skeleton's own coordinates, where y grows
downwards like any Solar2D display object. A skeleton drawn above its origin has a negative ``offsetY``.


Example
-------

.. code-block:: lua

    local size = skeleton:getSize()
    print("Size:", size.width, size.height, size.offsetX, size.offsetY)