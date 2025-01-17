===================================
slot:getAttachments()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`attachment`

Overview:
.........
--------

Returns a table of all attachments available for this slot. If you only want to know the current attachment, 
use :doc:`attachment` or if you want to know all the attachments for a given skin, use :doc:`getSkinAttachments`.

Syntax:
--------
--------

.. code-block:: lua

   local attachments = slot:getAttachments(slotName)


Return value:
-------------
-------------

``table`` – A table of strings, each representing an attachment name.

Example:
--------
--------

.. code-block:: lua

   local slot = skeleton.slots[1]
   local attachments = slot:getAttachments(slotName)

   for i = 1, #attachments do
       print("Attachment:", attachments[i])
   end
