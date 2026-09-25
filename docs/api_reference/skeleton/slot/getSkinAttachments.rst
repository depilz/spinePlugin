===================================
slot:getSkinAttachments()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`attachment`

Overview:
.........

Returns a table of attachment objects available for this slot in the currently
applied skin, or in a skin specified by name.

Syntax:
--------

.. code-block:: lua

   local attachments = slot:getSkinAttachments()
   local attachments = slot:getSkinAttachments(nil)
   local attachments = slot:getSkinAttachments("skinName")

- ``skinName`` *(optional)*:
    ``string`` – The name of the skin to get attachments from. If omitted or
    ``nil``, the currently applied skin is used. If no skin is applied, the
    skeleton data's default skin is used instead.

Return value:
-------------

``table`` – An array of :doc:`attachment objects </api_reference/attachment/index>`.
The table is empty if the selected skin has no attachments for this slot.
Returns ``nil`` if the named skin does not exist or no current/default skin is available.

This method lists only the selected skin's attachments. Use :doc:`getAttachments`
to list attachments across registered skins. Use :doc:`getAttachmentEntries`
to inspect lookup keys or include the effective default-skin fallback.


Example:
--------

.. code-block:: lua

    local slot = skeleton.slots[1]
    local attachments = slot:getSkinAttachments(nil)
    
    for _, attachment in ipairs(attachments or {}) do
         print("Attachment:", attachment.name)
    end
