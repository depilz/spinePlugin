=======================================
skeleton
=======================================

| **Parent**: `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_
| **See also**: :doc:`../spine/create`

........
Overview
........
--------

A **Skeleton** object is returned when you call:

.. code-block:: lua

   local mySkeleton = spine.create(skeletonData)


This is the core element of the Spine plugin, representing the animated character or object. The 
Skeleton object provides methods and properties to manipulate the skeleton's bones, slots, and animations.

It inherits all the properties and methods of a `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_.

Properties
----------
----------

*(Inherits properties from* `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_.)

.. toctree::
   :maxdepth: 1

   isActive
   timeScale
   slots
   bones
   ikConstraints
   physics/index
   tracks

Methods
-------
-------

*(Inherits methods from* `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_.)

Skin Management
...............  

.. toctree::
   :maxdepth: 1

   setSkin
   getSkins

Setup Pose
.............

.. toctree::
   :maxdepth: 1

   setToSetupPose
   setBonesToSetupPose
   setSlotsToSetupPose

Animation Control
.................

.. toctree::
   :maxdepth: 1

   setAnimation
   addAnimation
   setEmptyAnimation
   addEmptyAnimation
   findAnimation
   getCurrentAnimation
   getAnimations

Animation Mixing
................

.. toctree::
   :maxdepth: 1

   setDefaultMix
   setMix

Update & Rendering
...................

.. toctree::
   :maxdepth: 1

   updateState
   draw

Attachment / Slot Management
.............................

.. toctree::
   :maxdepth: 1

   setAttachment
   getAttachments
   findSlot
   getSlot
   getSlotNames

IK Constraints
..............

.. toctree::
   :maxdepth: 1

   getIKConstraint
   getIKConstraintNames

Miscellaneous
.............

.. toctree::
   :maxdepth: 1

   setFillColor
   inject
   eject
   clearTracks
   clearTrack