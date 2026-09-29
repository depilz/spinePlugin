===================================
skeleton:setToSetupPose()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setSlotsToSetupPose`, :doc:`setBonesToSetupPose`

Overview:
.........
--------

Resets all bones and slots to their *setup pose* as defined in Spine. This is useful
when you need to revert the entire skeleton to its default, un-animated state.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:setToSetupPose()

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   -- Apply some animations, then later reset to setup pose
   hero:setAnimation(1, "walk", true)

   -- Revert to the default pose
   hero:setToSetupPose()
   hero:draw()