slot:getAttachmentEntries()
===========================

Returns entries containing usable skin lookup keys and their attachment objects.

.. fragment: syntax lines; slot and goldSkin are placeholders
.. code-block:: lua

   local effective = slot:getAttachmentEntries()
   local effective = slot:getAttachmentEntries(nil)
   local specific = slot:getAttachmentEntries("gold")
   local specific = slot:getAttachmentEntries(goldSkin)

Without a name, searches current skin then default skin, including each lookup
key once. Current-skin entries override default entries with the same key.
With a skin name or a Skin object, lists only that skin; an unknown name, a wrong type or a skin of other
skeleton data raises.
A valid skin with no entries, or no available current/default skin, returns ``{}``.
Array ordering is unspecified.

Each entry contains:

- ``slotName``: the name of this slot.
- ``placeholder``: the lookup key (skin placeholder name), which can differ from the object's name.
- ``skinName``: the source skin's name.
- ``attachment``: an :doc:`attachment object </api_reference/attachment/index>`.

.. code-block:: lua

   local slot = hero:getSlot("hand1")
   for _, entry in ipairs(slot:getAttachmentEntries()) do
       print(entry.placeholder, entry.attachment.name, entry.skinName)
   end

See :doc:`/attachments-and-skins` for lookup, sharing, and animation behavior.
