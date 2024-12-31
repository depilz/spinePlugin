===================================
skeleton:getAttachments(slotName)
===================================

| **Type:** Method
| **See also:** :doc:`index`, :doc:`setAttachment`

Overview:
.........
--------

Returns a table of all attachments for a given slot name.

Syntax:
--------
--------

.. code-block:: lua

   local attachments = skeleton:getAttachments(slotName)

- ``slotName`` *(required)*:
    ``string`` – The name of the slot to search for.

Return value:
-------------
-------------

``table`` – A table of strings, each representing an attachment name.

Example:
--------
--------

.. code-block:: lua

    local attachments = hero:getAttachments("head")
    for i = 1, #attachments do
         print("Attachment:", attachments[i])
    end