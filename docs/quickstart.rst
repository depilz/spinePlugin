===================================
Quick Start Guide
===================================

This quick start guide walks you through the **minimum steps** to get a
Spine skeleton animating with your Spine plugin in Solar2D. By the end,
you’ll have a character (or object) loaded, animated, and rendered in
the simulator or on a device.

1. Installation & Requirements
------------------------------
- **Solar2D**: Make sure you have the latest Solar2D build, the plugin is
  compatible only with `Solar2D-3713` or later.
- **Spine License**: You need a valid Spine runtime license to use this
  plugin. Confirm you have the necessary permissions to use the runtime.
- **Spine Plugin**: Include it in your project’s ``build.settings`` or
  reference it in the Solar2D Marketplace.

.. code-block:: lua

   settings = {
     plugins = {
       ["plugin.spine"] = {
         publisherId = "com.studycat" 
       },
     },
   }

2. Require the Plugin
---------------------

At the start of your code (e.g., ``main.lua``), require the Spine
plugin:

.. code-block:: lua

   local spine = require("plugin.spine")

3. Load the Atlas & Skeleton Data
---------------------------------
Load your **atlas** (the texture mapping file) and **skeleton data**
(JSON or binary) from Spine. Make sure these files are included in your
Solar2D project’s resource directory:

.. code-block:: lua

   local atlas = spine.loadAtlas("assets/hero.atlas")
   local skeletonData = spine.loadSkeletonData("assets/hero.skel", atlas)

   -- Optionally provide a scale factor:
   -- local skeletonData = spine.loadSkeletonData("assets/hero.skel", atlas, 0.5)

4. Create the Skeleton
----------------------
Create a skeleton from the loaded skeleton data. Optionally, you can
provide a listener function to handle animation events (e.g., footsteps,
attack triggers).

.. code-block:: lua

   local function onSpineEvent(event)
       if event.name == "spine" then
           print("Custom Spine event:", event.phase)
       end
   end

   local hero = spine.create(skeletonData, onSpineEvent)

   -- Position the skeleton in the center of the screen
   hero.x = display.contentCenterX
   hero.y = display.contentCenterY

5. Set an Animation
-------------------
Choose an animation to play on a track. In Solar2D + Spine, tracks are
indexed starting at **1** by default in this plugin (but check your doc
if it’s 0-based or 1-based). Set loop to `true` or `false`.

.. code-block:: lua

   hero:setAnimation(1, "walk", true)

   -- Or queue animations
   -- hero:addAnimation(1, "run", true, 200)

6. Update & Draw Each Frame
---------------------------

In order for the skeleton to animate, you need to:
1. **Calculate delta time** (in milliseconds).
2. **Call** `hero:updateState(dt)` to advance animations.
3. **Call** `hero:draw()` to render the skeleton.

A typical approach using **system.getTimer**:

.. code-block:: lua

   local lastTime = system.getTimer()

   local function onEnterFrame(event)
       local now = system.getTimer()
       local dt = now - lastTime
       lastTime = now

       hero:updateState(dt)  -- advance the skeleton animations
       hero:draw()           -- render the skeleton
   end

   Runtime:addEventListener("enterFrame", onEnterFrame)

7. That’s It—You’re Animating!
------------------------------

At this point, you have:

- **Installed** the plugin
- **Loaded** a Spine atlas & skeleton data
- **Created** a skeleton
- **Set** an animation
- **Driven** updates with `updateState`
- **Rendered** each frame with `draw`

Take it further by:

- Using :doc:`skeleton <../api_reference/skeleton/index>` to manipulate bones, slots,
  or time scale.
- Controlling advanced transitions with :doc:`trackEntry <../api_reference/skeleton/trackEntry/index>`.
- Setting up :doc:`physics <../api_reference/skeleton/physics/index>` for physically driven
  skeleton constraints.
- Changing skins with :doc:`skeleton.setSkin <api_reference/skeleton/setSkin>` for
  different costumes.

------------------------------

Congratulations on getting your first **Solar2D + Spine** character
on-screen and animating in just a few steps!