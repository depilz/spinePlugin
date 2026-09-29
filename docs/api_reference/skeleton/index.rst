=======================================
skeleton
=======================================

| **Parent**: `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_
| **See also**: :doc:`../spine/create`

..........
Overview:
..........

A **Skeleton** object is returned when you call:

.. fragment: syntax line; skeletonData is a placeholder
.. code-block:: lua

   local mySkeleton = spine.create(skeletonData)


This is the core element of the Spine plugin, representing the animated character or object. The
Skeleton object provides methods and properties to manipulate the skeleton's bones, slots, and animations.

It inherits all the properties and methods of a `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_.
The display object follows Solar2D's naming, and every Spine object follows Spine's: see :doc:`/naming`.

The plugin keeps its own data on the display group under the key ``_skeleton``. ``_skeleton`` and every other key
that starts with ``_`` on a skeleton object is private: it is not part of the API, and clearing or overwriting it
is unsupported.

Properties
----------

*(Inherits properties from* `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_.)

.. toctree::
   :maxdepth: 1

   isActive
   timeScale
   physicsTimeScale
   numChildren
   slots
   bones
   ikConstraints
   physics
   physics/index
   tracks

Methods
-------

*(Inherits methods from* `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_.)

Skin Management
...............

.. toctree::
   :maxdepth: 1

   setSkin
   getSkin
   findSkin
   getSkins
   createSkin

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
   addAnimationAt
   findAnimation
   getAnimations
   getCurrentAnimation
   getTrackEntry
   setEmptyAnimation
   addEmptyAnimation
   setEmptyAnimations
   setListener
   clearTracks
   clearTrack

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
   getSize
   getBounds

Hit Testing
...........

.. toctree::
   :maxdepth: 1

   hitTest

Attachment / Slot Management
.............................

.. toctree::
   :maxdepth: 1

   setAttachment
   findSlot
   getSlot
   getSlotNames
   getDrawOrder

IK Constraints
..............

.. toctree::
   :maxdepth: 1

   getIKConstraint
   getIKConstraintNames

Injections
.............

.. toctree::
   :maxdepth: 1

   inject
   injectionEvent
   changeInjectionSlot
   eject

Splits
.............

.. toctree::
   :maxdepth: 1

   split
   reassemble


Effects
.............

.. toctree::
   :maxdepth: 1

   setFillColor
   fill

Removal
.............

.. toctree::
   :maxdepth: 1

   removeSelf

Aliases
-------

See :doc:`/naming`.
