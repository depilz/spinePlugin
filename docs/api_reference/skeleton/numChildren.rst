===================================
skeleton.numChildren
===================================

| **Type:** ``nil``
| **See also:** :doc:`index`, :doc:`inject`

Overview:
.........

The skeleton is a display group, but the group's children are the meshes the plugin draws the skeleton with, not
part of the API. ``skeleton.numChildren`` therefore reads ``nil``, on a live skeleton as on a removed one. To attach a
display object to the skeleton, use :doc:`inject`.

Example:
--------

.. code-block:: lua

   print(spineboy.numChildren)  -- nil
