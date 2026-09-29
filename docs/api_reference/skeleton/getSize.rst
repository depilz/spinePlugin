===================================
skeleton:getSize()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getBounds`

Overview:
.........
---------

Returns the current size of the skeleton and the offset from the origin point.

Syntax:
--------
--------

.. code-block:: lua

   local size = skeleton:getSize()

Return value:
-------------
-------------

``size`` – A table with the following fields:

- ``width``: ``number`` – The width of the skeleton.

- ``height``: ``number`` – The height of the skeleton.

- ``offsetX``: ``number`` – The offset from the origin point on the X-axis.

- ``offsetY``: ``number`` – The offset from the origin point on the Y-axis.


Example:
---------
---------

.. code-block:: lua

    local size = skeleton:getSize()
    print("Size:", size.width, size.height, size.offsetX, size.offsetY)