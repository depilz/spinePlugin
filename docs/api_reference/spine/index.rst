=======================================
spine
=======================================

| **Type:** ``table``
| **See also:** :doc:`../skeleton/index`

Overview
--------

This page documents the Lua API made available when you:

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")

The returned ``spine`` table contains core methods for loading atlases,
loading SkeletonData, and creating new Spine objects in Solar2D.


Properties
----------

.. toctree::
   :maxdepth: 1

   version <version>
   runtimeVersion <runtimeVersion>


Methods
-------

.. toctree::
   :maxdepth: 1

   loadAtlas() <loadAtlas>
   loadSkeletonData() <loadSkeletonData>
   create() <create>
   spineEvent <event>
