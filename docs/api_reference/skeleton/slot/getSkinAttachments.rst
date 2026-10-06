===================================
slot:getSkinAttachments()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`attachment`

Overview
--------

Returns a table of attachment objects available for this slot in the currently
applied skin, or in a skin specified by name or Skin object.

Syntax
------

.. fragment: syntax line; slot and the arguments are placeholders
.. code-block:: lua

   local attachments = slot:getSkinAttachments()
   local attachments = slot:getSkinAttachments(nil)
   local attachments = slot:getSkinAttachments("skinName")
   local attachments = slot:getSkinAttachments(skin)

Parameters
----------

- ``skin`` *(optional)*:
    ``string`` or ``Skin`` – The name of the skin to get attachments from, or a Skin object of the same
    skeleton data. A name finds only the skeleton data's skins, so a skin made with
    ``skeleton:createSkin()`` must be passed as the Skin object. If omitted or
    ``nil``, the currently applied skin is used. If no skin is applied, the
    skeleton data's default skin is used instead.

Return value
------------

``table`` – An array of :doc:`attachment objects </api_reference/attachment/index>`.
The table is empty if the selected skin has no attachments for this slot.
The table is also empty if no current/default skin is available. An unknown skin name, a wrong type or a
skin of other skeleton data raises.

This method lists only the selected skin's attachments. Use :doc:`getAttachments`
to list attachments across the skeleton data's skins. Use :doc:`getAttachmentEntries`
to inspect lookup keys or include the effective default-skin fallback.


Example
-------

.. code-block:: lua

    local slot = skeleton.slots[1]
    local attachments = slot:getSkinAttachments(nil)

    for _, attachment in ipairs(attachments or {}) do
         print("Attachment:", attachment.name)
    end
