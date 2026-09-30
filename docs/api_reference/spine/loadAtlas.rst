=======================================
spine.loadAtlas()
=======================================

| **Type:** ``function``
| **Return value:** Atlas userdata
| **See also:** :doc:`index`, :doc:`loadSkeletonData`

Overview:
----------

Loads a Spine atlas (``.atlas``) file from the given path and creates
an internal representation of it in memory.

Gotchas:
........

The textures are loaded by the atlases and those textures are only released
when the atlas object is garbage collected, so as long as you hold references
to the atlas object or the atlas is still in use by a skeleton, the
textures will be kept in memory. This is why reusing atlases is good.

If a page texture cannot be loaded, ``loadAtlas`` raises ``Failed to load texture: <path>``, followed by
``: <reason>`` when Solar2D's ``graphics.newTexture`` raised an error.
The atlas and the pages that did load are released first, so a failed call keeps nothing in memory.

Premultiplied alpha is not supported: the plugin draws straight alpha (see :doc:`../skeleton/fill/effect`). When any
page of the atlas declares ``pma: true`` (the Spine texture packer's "Premultiply alpha" option), ``loadAtlas``
still loads the atlas and returns it, and prints one line through Lua ``print``, once per call, with the path as
passed:

.. code-block:: text

   WARNING: plugin.spine: <path>: premultiplied-alpha atlas (pma: true) is not supported; export with straight alpha

Export the atlas again with "Premultiply alpha" turned off.


Syntax:
...........

.. fragment: syntax line; path is a placeholder
.. code-block:: lua

   local atlas = spine.loadAtlas(path)


- ``path`` *(required)*:
    ``string`` – The relative path to your atlas file.

Return Values:
..................

- ``userdata`` – A Lua userdata wrapping the underlying C++ Atlas object (its metatable is named ``Atlas``). You’ll use this when loading SkeletonData.



Example:
............

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
