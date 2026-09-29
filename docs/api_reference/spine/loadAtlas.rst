=======================================
spine.loadAtlas()
=======================================

| **Type:** ``function``
| **Return value:** Atlas userdata
| **See also:** :doc:`index`, :doc:`loadSkeletonData`

Overview:
----------
----------

Loads a Spine atlas (``.atlas``) file from the given path and creates
an internal representation of it in memory.

Gotchas:
........
--------

The textures are loaded by the atlases and those textures are only released
when the atlas object is garbage collected, so as long as you hold references
to the atlas object or the atlas is still in use by a skeleton, the 
textures will be kept in memory. This is why reusing atlases is good.


Syntax:
...........
--------

.. code-block:: lua

   local atlas = spine.loadAtlas(path)


- ``path`` *(required)*:
    ``string`` – The relative path to your atlas file.

Return Values:
..................
--------

- ``userdata`` – A Lua userdata wrapping the underlying C++ Atlas object. You’ll use this when loading SkeletonData.



Example:
............
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("assets/characters/hero.atlas")
