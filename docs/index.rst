================================================
Welcome to the Solar2D's Spine Documentation!
================================================

| *(Jump straight to the* :doc:`API reference <api_reference/index>`)

Introduction
------------

This documentation is your comprehensive guide to integrating and using
the **Spine Plugin** within your `Solar2D <https://solar2d.com>`_ projects. If you’re looking for
powerful 2D skeletal animations—complete with mixing, blending, skin
switching, and event handling—this plugin is designed to streamline your
animation workflow.

Spine (developed by `Esoteric Software <https://esotericsoftware.com>`_)
is a popular tool for creating 2D skeletal animations. With this plugin,
you can seamlessly play back and control Spine animations in your
Solar2D games or applications. The result: beautiful and efficient
character or UI animations that look great on every device.

.. _pick-your-line:

Pick your line
--------------

The plugin ships one plugin per Spine line. Pick the line of the Spine editor you export your skeletons from, add
its entry to the plugins table of ``build.settings`` and read that line's documentation. Use one Spine plugin per app:
``plugin.spine42`` and ``plugin.spine43`` raise an error naming both plugins when the other line or the legacy
``plugin.spine`` is already loaded, but a legacy ``plugin.spine`` required after them cannot check and is not caught.

- **Spine 4.2**: ``plugin.spine42`` (version 2.0.0), `documentation for 4.2 <https://spineplugin.readthedocs.io/en/4.2/>`_.

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

- **Spine 4.3**: ``plugin.spine43`` (version 3.0.0), `documentation for 4.3 <https://spineplugin.readthedocs.io/en/4.3/>`_.

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

- **Legacy 1.2**: ``plugin.spine``, the earlier release, `documentation for 1.2 <https://spineplugin.readthedocs.io/en/1.2/>`_.

  .. code-block:: lua

      settings =
      {
          plugins =
          {
              ["plugin.spine"] =
              {
                  publisherId = "com.studycat",
              },
          },
      }

Moving a project from ``plugin.spine`` 1.2 to a line, or from 4.2 to 4.3? See the :doc:`migration guide <migration>`
and the CHANGELOG's `plugin.spine42 2.0.0`_ and `plugin.spine43 3.0.0`_ releases.

How to Get Started
------------------

1. **Check Spine License Requirements**

   Make sure you own a valid Spine license if necessary. Esoteric
   Software offers various Spine license tiers. Confirm you have the
   permission required to use the runtime.

2. **Install the Plugin**

   .. only:: spine42

      To use this plugin, add this entry into the plugins table of build.settings. The Simulator and the build download
      the plugin from its GitHub release, one archive per platform, from the URLs in the entry.
      This is the entry for the line these docs describe; :ref:`pick-your-line` lists the entry of every line.

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

      To use this plugin, add this entry into the plugins table of build.settings. The Simulator and the build download
      the plugin from its GitHub release, one archive per platform, from the URLs in the entry.
      This is the entry for the line these docs describe; :ref:`pick-your-line` lists the entry of every line.

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


3. **Load the Plugin in Your Lua Code**

   .. code-block:: lua

       local spine = require("@SPINE_PLUGIN@")


4. **Import Your Spine Assets**

   Put your Spine-generated JSON or binary skeleton files, as well as
   any atlas/textures, into your project’s resource directory.

5. **Start Animating**

   Familiarize yourself with the plugin’s core objects (e.g., Skeleton, physics, ik constraints)
   and methods. These are detailed in the :doc:`api_reference/index`. You’ll learn how to
   mix animations, update skeleton transforms, change skins, and more.



Differences from the Original Spine Runtime:
---------------------------------------------

I built this plugin trying to make a complete integration to the original C++ Runtime. However,
there are some key differences to keep in mind:

* **indexes**: Indexes start at ``1``, not ``0``, including track indexes. Skin methods take slot names or Slot objects, never numeric slot indexes. Not my favorite change, but I want to prioritize consistency with the language and the engine first, and then with the original runtime.

* **events**: Events have been customized to be more Solar2D-friendly. Event phases are ``"began"``, ``"completed"``, and ``"ended"`` instead of ``"start"``, ``"complete"``, and ``"end"``. (See :doc:`api_reference/spine/event` for more details).

* **times**: All times are in milliseconds, not seconds. This is to keep consistency with Solar2D's time units.

* **AnimationState**: The AnimationState class has been removed. Instead, the Skeleton class has all the necessary methods to control animations.



Key Features
------------

- **Compatibility**: The plugin is compatible with Solar2D builds for iOS, Android, macOS and windows.

- **Performance**: Unlike the old Lua Runtime, this plugin uses native code for optimal rendering and animation performance.

.. only:: spine42

   - **Physics**: This line uses Spine 4.2, which has the new physics system. You can now create physics constraints in Spine and use them in Solar2D.

.. only:: spine43

   - **Physics**: This line uses Spine 4.3, which has the physics system. You can create physics constraints in Spine and use them in Solar2D.


Documentation Contents
----------------------

Below is a quick look at the main sections of this documentation:

.. toctree::
    :maxdepth: 1

    quickstart
    attachments-and-skins
    lifecycle
    naming
    migration

.. toctree::
   :maxdepth: 2

   api_reference/index

.. toctree::
   :maxdepth: 1

   about
   contact
   legal

Feedback & Contributions
------------------------

We’re always looking to improve! If you run into any issues or have
suggestions:

- **GitHub**: Submit bug reports, feature requests, or pull requests to the `repository <https://github.com/depilz/spinePlugin>`_.

- **Community Forums**: Join the discussion on the `Solar2D Community Forums <https://forums.solar2d.com/>`_.

- **Support**: For more direct inquiries, check our `Support Guidelines <https://github.com/depilz/spinePlugin/issues>`_.

License
-------

This project is subject to the `Spine Runtimes License
<https://esotericsoftware.com/spine-runtimes-license>`_. Feel free to fork or modify
the plugin code for your projects, but please respect the license terms.

Acknowledgments
---------------

- Thanks to `Studycat Limited <https://studycat.com>`_ for supporting me in bringing this project to
  life while I was working at the company.
- Big thanks to `Steven Johnson (ggcrunchy) <https://github.com/ggcrunchy>`_
  for his unwavering support and contributions.
- Thanks to the `Esoteric Software <https://esotericsoftware.com>`_
  team for developing and maintaining Spine.

.. note::

   This plugin is independently maintained and is **not** officially
   endorsed by Esoteric Software.

----------------------------------

We hope you find this documentation helpful and comprehensive.
Let’s get animating with Spine for Solar2D!

.. _plugin.spine42 2.0.0: https://github.com/depilz/spinePlugin/blob/main/CHANGELOG.md#pluginspine42-200
.. _plugin.spine43 3.0.0: https://github.com/depilz/spinePlugin/blob/main/CHANGELOG.md#pluginspine43-300
