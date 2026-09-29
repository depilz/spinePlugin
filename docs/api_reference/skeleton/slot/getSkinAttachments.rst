===================================
slot:getSkinAttachments()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`attachment`

Overview:
.........
--------

Returns a table of all attachments available for this slot for a given skin.

Syntax:
--------
--------

.. code-block:: lua

   local attachments = slot:getSkinAttachments([skinName])

- ``skinName`` *(optional)*:
    ``string`` – The name of the skin to get attachments from. If omitted, the default skin is used.

Return value:
-------------
-------------

``table`` – A table of strings, each representing an attachment name.


Example:
--------
--------

.. code-block:: lua

    local slot = skeleton.slots[1]
    local attachments = slot:getSkinAttachments("skinName")
    
    for i = 1, #attachments do
         print("Attachment:", attachments[i])
    end