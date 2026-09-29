================================================
Welcome to the Solar2D's Spine Documentation!
================================================

| *(Jump straight to the* :doc:`API reference <api_reference/index>`)

Introduction
------------
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

How to Get Started
------------------
------------------

1. **Check Spine License Requirements**  

   Make sure you own a valid Spine license if necessary. Esoteric
   Software offers various Spine license tiers. Confirm you have the
   permission required to use the runtime.

2. **Install the Plugin**  

   To use this plugin, add an entry into the plugins table of build.settings. When added, the build server will integrate the plugin during the build phase.

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


3. **Load the Plugin in Your Lua Code**  

   .. code-block:: lua
   
       local spine = require("plugin.spine")


4. **Import Your Spine Assets**  

   Put your Spine-generated JSON or binary skeleton files, as well as
   any atlas/textures, into your project’s resource directory.  

5. **Start Animating**  

   Familiarize yourself with the plugin’s core objects (e.g., Skeleton, physics, ik constraints) 
   and methods. These are detailed in the :doc:`api_reference/index`. You’ll learn how to
   mix animations, update skeleton transforms, change skins, and more.



Differences from the Original Spine Runtime:
---------------------------------------------
---------------------------------------------

I built this plugin trying to make a complete integration to the original C++ Runtime. However, 
there are some key differences to keep in mind:

* **indexes**: Indexes start at ``1``, not ``0``, including track indexes. Not my favorite change, but I want to prioritize consistency with the language and the engine first, and then with the original runtime.

* **events**: Events have been customized to be more Solar2D-friendly. Event phases are ``"began"``, ``"completed"``, and ``"ended"`` instead of ``"start"``, ``"complete"``, and ``"end"``. (See :doc:`api_reference/spine/event` for more details).

* **times**: All times are in milliseconds, not seconds. This is to keep consistency with Solar2D's time units.

* **AnimationState**: The AnimationState class has been removed. Instead, the Skeleton class has all the necessary methods to control animations.



Key Features
------------
------------

- **Compatibility**: The plugin is compatible with Solar2D builds for iOS, Android, macOS and windows.

- **Performance**: Unlike the old Lua Runtime, this plugin uses native code for optimal rendering and animation performance.

- **Physics**: The plugin uses spine 4.2, which has the new physics system. You can now create physics constraints in Spine and use them in Solar2D.


Documentation Contents
----------------------
----------------------

Below is a quick look at the main sections of this documentation:

.. toctree::
    :maxdepth: 1

    quickstart

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
------------------------

We’re always looking to improve! If you run into any issues or have
suggestions:

- **GitHub**: Submit bug reports, feature requests, or pull requests to the `repository <https://github.com/depilz/spinePlugin>`_.

- **Community Forums**: Join the discussion on the `Solar2D Community Forums <https://forums.solar2d.com/>`_.

- **Support**: For more direct inquiries, check our `Support Guidelines <https://github.com/depilz/spinePlugin/issues>`_.

License
-------
-------

This project is subject to the `Spine Runtimes License
<https://esotericsoftware.com/spine-runtimes-license>`_. Feel free to fork or modify
the plugin code for your projects, but please respect the license terms.

Acknowledgments
---------------
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
