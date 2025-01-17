===================================
skeleton:getBounds()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getSize`

Overview:
.........
---------

Returns a table with the bounding box of the skeleton. The bounding box is the smallest 
rectangle that contains all the bones of the skeleton.

These bounds are relative to the skeleton's origin point., if you want them to be in content coordinates
you can use the `skeleton.contentBounds <https://docs.coronalabs.com/api/type/DisplayObject/contentBounds.html>`_ 
instead.


Syntax:
--------
--------

.. code-block:: lua

    local bounds = skeleton:getBounds()

Return value:
-------------
-------------

``bounds`` – A table with the following fields:

- ``xMin``: ``number`` – The minimum X value of the bounding box.

- ``yMin``: ``number`` – The minimum Y value of the bounding box.

- ``xMax``: ``number`` – The maximum X value of the bounding box.

- ``yMax``: ``number`` – The maximum Y value of the bounding box.

Example:
---------
---------

.. code-block:: lua

    local bounds = skeleton:getBounds()
    print("Bounds:", bounds.xMin, bounds.yMin, bounds.xMax, bounds.yMax)