=======================================
skin
=======================================

| **See also**: :doc:`../skeleton/createSkin`, :doc:`../skeleton/getSkin`

..........
Overview:
..........

A **Skin** object represents a collection of attachments (images, meshes, etc.) that can be applied to a skeleton. Skins enable character customization by allowing you to swap or combine different visual elements.

Custom Skin objects are created using :doc:`../skeleton/createSkin` and can combine attachments from multiple existing skins for mix-and-match customization.

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

