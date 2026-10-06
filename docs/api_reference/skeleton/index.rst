=======================================
skeleton
=======================================

| **Parent:** `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_
| **See also:** :doc:`../spine/create`

Overview
--------

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

   isActive <isActive>
   timeScale <timeScale>
   physicsTimeScale <physicsTimeScale>
   numChildren <numChildren>
   slots <slots>
   bones <bones>
   ikConstraints <ikConstraints>
   sliders <sliders>
   physics <physics>
   tracks <tracks>

Methods
-------

*(Inherits methods from* `DisplayObject <https://docs.coronalabs.com/api/type/DisplayObject/index.html>`_.)

Skin Management
~~~~~~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   setSkin() <setSkin>
   getSkin() <getSkin>
   findSkin() <findSkin>
   getSkins() <getSkins>
   createSkin() <createSkin>
   createAttachment() <createAttachment>

Setup Pose
~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   setToSetupPose() <setToSetupPose>
   setBonesToSetupPose() <setBonesToSetupPose>
   setSlotsToSetupPose() <setSlotsToSetupPose>

Animation Control
~~~~~~~~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   setAnimation() <setAnimation>
   addAnimation() <addAnimation>
   addAnimationAt() <addAnimationAt>
   findAnimation() <findAnimation>
   getAnimations() <getAnimations>
   getCurrentAnimation() <getCurrentAnimation>
   getTrackEntry() <getTrackEntry>
   setEmptyAnimation() <setEmptyAnimation>
   addEmptyAnimation() <addEmptyAnimation>
   setEmptyAnimations() <setEmptyAnimations>
   setListener() <setListener>
   clearTracks() <clearTracks>
   clearTrack() <clearTrack>

Animation Mixing
~~~~~~~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   setDefaultMix() <setDefaultMix>
   setMix() <setMix>

Update & Rendering
~~~~~~~~~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   updateState() <updateState>
   draw() <draw>
   getSize() <getSize>
   getBounds() <getBounds>

Hit Testing
~~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   hitTest() <hitTest>

Attachment / Slot Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   setAttachment() <setAttachment>
   findSlot() <findSlot>
   getSlot() <getSlot>
   getSlotNames() <getSlotNames>
   getDrawOrder() <getDrawOrder>

IK Constraints
~~~~~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   getIkConstraint() <getIKConstraint>
   getIkConstraintNames() <getIKConstraintNames>

Injections
~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   inject() <inject>
   injectionEvent <injectionEvent>
   changeInjectionSlot() <changeInjectionSlot>
   eject() <eject>

Splits
~~~~~~

.. toctree::
   :maxdepth: 1

   split() <split>
   reassemble() <reassemble>


Effects
~~~~~~~

.. toctree::
   :maxdepth: 1

   setFillColor() <setFillColor>
   fill <fill>

Removal
~~~~~~~

.. toctree::
   :maxdepth: 1

   removeSelf() <removeSelf>

Aliases
-------

See :doc:`/naming`.
