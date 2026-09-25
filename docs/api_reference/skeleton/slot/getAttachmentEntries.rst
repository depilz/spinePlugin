slot:getAttachmentEntries()
===========================

Returns entries containing usable skin lookup keys and their attachment objects.

.. code-block:: lua

   local effective = slot:getAttachmentEntries()
   local effective = slot:getAttachmentEntries(nil)
   local specific = slot:getAttachmentEntries("gold")

Without a name, searches current skin then default skin, including each lookup
key once. Current-skin entries override default entries with the same key.
With a name, lists only that registered skin; an unknown name returns ``nil``.
A valid skin with no entries, or no available current/default skin, returns ``{}``.
Array ordering is unspecified.

Each entry contains:

- ``name``: the lookup key (skin placeholder name), which can differ from the object's name.
- ``attachment``: an :doc:`attachment object </api_reference/attachment/index>`.
- ``skinName``: the source skin's name. A current custom skin need not be registered.
- ``slotIndex``: the zero-based slot index.

.. code-block:: lua

   for _, entry in ipairs(slot:getAttachmentEntries()) do
       print(entry.name, entry.attachment.name, entry.skinName)
   end

See :doc:`/attachments-and-skins` for lookup, sharing, and animation behavior.
