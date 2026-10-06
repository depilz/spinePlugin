===============================================
spine.loadSkeletonData()
===============================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`loadAtlas`

Overview
--------

Loads Spine skeleton data (``.json`` or ``.skel``) from the specified path using a previously loaded atlas. This function parses the skeleton data and prepares it for animation within your Solar2D project. Optionally, you can provide a scale factor to adjust the size of the skeleton.

Syntax
------

.. fragment: syntax line; arguments are placeholders
.. code-block:: lua

   local skeletonData = spine.loadSkeletonData(path, atlas, [scale])

Parameters
----------

- ``path`` *(required)*:
    ``string`` – The relative path to your skeleton data file (either ``.json`` or ``.skel``).

- ``atlas`` *(required)*:
    ``userdata`` – The atlas userdata returned by ``spine.loadAtlas()``. This atlas contains texture information required by the skeleton.

- ``scale`` *(optional)*:
    ``number`` – A scaling factor to apply to the skeleton. Defaults to ``1.0``.

Return value
------------

- ``userdata`` – A Lua userdata wrapping the underlying C++ ``SkeletonData`` object. This userdata is used when creating skeleton instances with ``spine.create()``.

Example
-------

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")

   -- Load the atlas
   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")

   -- Load skeleton data with a scale factor of 0.75
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas, 0.75)

   -- Create the skeleton
   local spineboy = spine.create(skeletonData)

   -- Set an animation
   spineboy:setAnimation(1, "walk", true)

   -- Update the skeleton each frame
   local lastTime = system.getTimer()
   local function onEnterFrame(event)
       local deltaTime = event.time - lastTime  -- milliseconds since the last frame
       lastTime = event.time
       spineboy:updateState(deltaTime)
       spineboy:draw()
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)

Notes
-----

The referenced atlas and the skeleton data will remain alive as long as this object is
alive or has references to it.

The scale, if provided, will affect all skeletons created with this skeleton data. Alternatively you
can scale the skeleton instance directly.

.. Tested by tests/lifecycle/t35_load_errors (missing, skel, json).

If no file exists at ``path``, ``loadSkeletonData`` raises ``File not found: <path>``, with the path as you passed it.

It raises ``Failed to load skeleton data: <path>: <reason>``, where ``<path>`` is the full path Solar2D resolves and
``<reason>`` is the Spine runtime's message, for these files:

- a ``.skel`` file exported by another Spine version:
  ``Skeleton version <version> does not match runtime version <line>``;
- a ``.json`` file whose slot names a bone the file does not have: ``Slot bone not found: <bone>``.

Other malformed files are not guaranteed to raise: depending on the damage, the Spine runtime's reader can stop the
app instead. Export with the Spine editor version your plugin line supports.