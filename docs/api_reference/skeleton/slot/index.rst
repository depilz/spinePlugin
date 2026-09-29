===================================
slot
===================================

| **Type:** ``userdata``
| **See also:** :doc:`../slots`, :doc:`../index`


Overview:
..........

A **Slot** object represents the attachment slot for a bone in a Spine skeleton. It holds color
tints (RGBA), a current attachment, and a reference to its owning bone.
Each slot can be manipulated independently to change visuals (e.g., attachments)
or adjust colors.

Below is a list of the Slot’s properties. Most can be **read or written**, except for the slot
name and bone reference: writing those raises ``SpineSlot: property '<key>' is read-only``, and writing
a key that is not listed raises ``SpineSlot: unknown property '<key>'``.

Two Slot objects compare equal with ``==`` when they are the same slot of the same skeleton instance.
Comparing a slot of a removed skeleton raises ``Slot belongs to a removed skeleton``.

Properties:
-----------

.. toctree::
   :maxdepth: 1

   name
   bone
   attachment
   r
   g
   b
   a
   color
   darkColor

Methods:
--------

.. toctree::
   :maxdepth: 1

   setAttachmentFromSkin
   getAttachments
   getSkinAttachments
   getAttachmentEntries

Aliases:
--------

See :doc:`/naming`.

.. toctree::
   :maxdepth: 1

   alpha
