===================================
Quick Start Guide
===================================

This quick start guide walks you through the **minimum steps** to get a
Spine skeleton animating with your Spine plugin in Solar2D. By the end,
you’ll have a character (or object) loaded, animated, and rendered in
the simulator or on a device.

1. Installation & Requirements
------------------------------
- **Solar2D**: Use the latest Solar2D release. The plugin's tests run on
  Solar2D (Corona) build 3731.
- **Spine License**: You need a valid Spine runtime license to use this
  plugin. Confirm you have the necessary permissions to use the runtime.

.. only:: spine42

   - **Spine Plugin**: Include it in your project’s ``build.settings``. The
     Simulator and the build download the plugin from its GitHub release, one
     archive per platform, from the URLs in the entry. The entry below is for
     the line these docs describe; :ref:`pick-your-line` lists the entry of
     every line.

   .. code-block:: lua

      settings =
      {
          plugins =
          {
              ["plugin.spine42"] =
              {
                  publisherId = "com.studycat",
                  supportedPlatforms =
                  {
                      android        = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-android.tgz" },
                      iphone         = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-iphone.tgz" },
                      ["iphone-sim"] = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-iphone-sim.tgz" },
                      ["mac-sim"]    = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-mac-sim.tgz" },
                      ["win32-sim"]  = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-win32-sim.tgz" },
                      ["linux-sim"]  = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-linux-sim.tgz" },
                  },
              },
          },
      }

.. only:: spine43

   - **Spine Plugin**: Include it in your project’s ``build.settings``. The
     Simulator and the build download the plugin from its GitHub release, one
     archive per platform, from the URLs in the entry. The entry below is for
     the line these docs describe; :ref:`pick-your-line` lists the entry of
     every line.

   .. code-block:: lua

      settings =
      {
          plugins =
          {
              ["plugin.spine43"] =
              {
                  publisherId = "com.studycat",
                  supportedPlatforms =
                  {
                      android        = { url = "https://github.com/depilz/spinePlugin/releases/download/spine43-3.0.0/plugin.spine43-3.0.0-android.tgz" },
                      iphone         = { url = "https://github.com/depilz/spinePlugin/releases/download/spine43-3.0.0/plugin.spine43-3.0.0-iphone.tgz" },
                      ["iphone-sim"] = { url = "https://github.com/depilz/spinePlugin/releases/download/spine43-3.0.0/plugin.spine43-3.0.0-iphone-sim.tgz" },
                      ["mac-sim"]    = { url = "https://github.com/depilz/spinePlugin/releases/download/spine43-3.0.0/plugin.spine43-3.0.0-mac-sim.tgz" },
                      ["win32-sim"]  = { url = "https://github.com/depilz/spinePlugin/releases/download/spine43-3.0.0/plugin.spine43-3.0.0-win32-sim.tgz" },
                      ["linux-sim"]  = { url = "https://github.com/depilz/spinePlugin/releases/download/spine43-3.0.0/plugin.spine43-3.0.0-linux-sim.tgz" },
                  },
              },
          },
      }

2. Require the Plugin
---------------------

At the start of your code (e.g., ``main.lua``), require the Spine
plugin:

.. code-block:: lua

   local spine = require("@SPINE_PLUGIN@")

3. Load the Atlas & Skeleton Data
---------------------------------
Load your **atlas** (the texture mapping file) and **skeleton data**
(JSON or binary) from Spine. Make sure these files are included in your
Solar2D project’s resource directory:

.. code-block:: lua

   local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
   local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.json", atlas)

   -- Binary exports (.skel) load the same way; optionally provide a scale factor:
   -- local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas, 0.5)

4. Create the Skeleton
----------------------
Create a skeleton from the loaded skeleton data. Optionally, you can
provide a listener function to handle animation events (e.g., footsteps,
attack triggers).

.. fragment: continues step 3, it uses that step's skeletonData
.. code-block:: lua

   local function onSpineEvent(event)
       if event.name == "spine" then
           print("Custom Spine event:", event.phase)
       end
   end

   local spineboy = spine.create(skeletonData, onSpineEvent)

   -- Position the skeleton in the center of the screen
   spineboy.x = display.contentCenterX
   spineboy.y = display.contentCenterY

5. Set an Animation
-------------------
Choose an animation to play on a track. In this plugin, tracks are
indexed starting at **1**. Set loop to `true` or `false`.

.. code-block:: lua

   spineboy:setAnimation(1, "walk", true)

   -- Or queue animations
   -- spineboy:addAnimation(1, "run", true, 200)

6. Update & Draw Each Frame
---------------------------

The plugin never updates or draws a skeleton on its own: your app drives
both, every frame. In order for the skeleton to animate, you need to:
1. **Calculate delta time** (in milliseconds).
2. **Call** `spineboy:updateState(dt)` to advance animations.
3. **Call** `spineboy:draw()` to render the skeleton.

A typical approach using **system.getTimer**:

.. code-block:: lua

   local lastTime = system.getTimer()

   local function onEnterFrame(event)
       local now = system.getTimer()
       local dt = now - lastTime
       lastTime = now

       spineboy:updateState(dt)  -- advance the skeleton animations
       spineboy:draw()       -- render the skeleton
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