===================================
skeleton:getSkins()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setSkin`

Overview:
.........
---------

Returns a list of all available skin names within this skeleton’s data. Skins define different sets of attachments or character appearances.

Syntax:
--------
--------

.. code-block:: lua

   local skins = skeleton:getSkins()

Return Value:
-------------
-------------

- **table** – An array of skin names as strings.

Example:
--------
--------

.. code-block:: lua

   local spine = require("plugin.spine")
   local atlas = spine.loadAtlas("hero.atlas")
   local skeletonData = spine.loadSkeletonData("hero.skel", atlas)
   local hero = spine.create(skeletonData)

   local skins = hero:getSkins()
   for i, skinName in ipairs(skins) do
       print("Available skin:", skinName)
   end