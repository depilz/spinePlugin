===================================
slot:getAttachments()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`attachment`

Overview:
.........

Returns a table of all attachments available for this slot. If you only want to know the current attachment,
use :doc:`attachment` or if you want to know all the attachments for a given skin, use :doc:`getSkinAttachments`.

Syntax:
--------

.. fragment: syntax line; slot and the arguments are placeholders
.. code-block:: lua

   local attachments = slot:getAttachments()


Return value:
-------------

``table`` – An array of attachment objects from the skeleton data's skins.
Duplicates are possible. Custom skins are excluded. For usable lookup
keys and source skin names, use :doc:`getAttachmentEntries`.

Example:
--------

.. code-block:: lua

   local slot = skeleton.slots[1]
   local attachments = slot:getAttachments()

   for i = 1, #attachments do
       print("Attachment:", attachments[i].name)
   end
