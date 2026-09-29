=======================================
spine
=======================================

| **Type:** ``table``
| **See also:** :doc:`../skeleton/index`

Overview:
..........

This page documents the Lua API made available when you:

.. code-block:: lua

   local spine = require("plugin.spine")

The returned ``spine`` table contains core methods for loading atlases,
loading SkeletonData, and creating new Spine objects in Solar2D.


Properties:
-----------

- **spine.version**:
    ``string`` – The plugin version, for example ``"2.0.0"`` for ``plugin.spine42`` and ``"3.0.0"`` for
    ``plugin.spine43``.

- **spine.runtimeVersion**:
    ``string`` – The Spine runtime the plugin is built on: ``"4.2"`` or ``"4.3"``.


Methods:
--------

.. toctree::
   :maxdepth: 1

   loadAtlas
   loadSkeletonData
   create
   event