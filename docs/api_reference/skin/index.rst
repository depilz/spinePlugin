=======================================
skin
=======================================

| **See also**: :doc:`../skeleton/createSkin`, :doc:`../skeleton/getSkin`

..........
Overview:
..........

A **Skin** object represents a collection of attachments (images, meshes, etc.) that can be applied to a skeleton. Skins enable character customization by allowing you to swap or combine different visual elements.

Custom Skin objects are created using :doc:`../skeleton/createSkin` and can combine attachments from multiple existing skins for mix-and-match customization.

Data skins and custom skins
...........................

A **data skin** is a skin loaded with the skeleton data, as returned by :doc:`../skeleton/findSkin`, or by
:doc:`../skeleton/getSkin` while a data skin is applied. Data skins are **read-only**: every skin mutator
(:doc:`addSkin`, :doc:`copySkin`, :doc:`setAttachment`, :doc:`removeAttachment`, :doc:`clear`) and every color
write (``r``, ``g``, ``b``, ``a``, ``color``) raises
``Skin '<name>' is read-only (a data skin); use skeleton:createSkin() for a mutable skin``. A **custom skin**
from :doc:`../skeleton/createSkin` is mutable. Attachment property writes are not restricted: they change the
shared attachment object (use :doc:`../attachment/copy` for a separate one).

Arguments, errors and return values
...................................

- A **slot argument** is a slot name (string) or a Slot object of the same skeleton data; a **skin argument**
  is a skin name (string) or a Skin object of the same skeleton data. A string is always looked up as a name,
  and a Lua number raises.
- Calls that cannot do what was asked raise a Lua error: unknown slot or skin, wrong type, foreign
  skeleton data, read-only skin, unknown or read-only property (``SpineSkin: unknown property '<key>'``,
  ``SpineSkin: property '<key>' is read-only``). Only :doc:`getAttachment` returns ``nil``, for a missing entry.
- Mutators return the skin itself, so calls can be chained:
  ``skeleton:createSkin("outfit"):addSkin("body"):addSkin("hat")``.
- Two Skin objects compare equal with ``==`` when they wrap the same skin.

Properties
----------

.. toctree::
   :maxdepth: 1

   name
   r
   g
   b
   a
   color

Methods
-------

Skin Combination
................

.. toctree::
   :maxdepth: 1

   addSkin
   copySkin

Attachment Management
.....................

.. toctree::
   :maxdepth: 1

   setAttachment
   getAttachment
   removeAttachment
   clear
   getAttachments
   findNamesForSlot
   findAttachmentsForSlot

Skin Information
................

.. toctree::
   :maxdepth: 1

   getName
   getBones
   getConstraints

