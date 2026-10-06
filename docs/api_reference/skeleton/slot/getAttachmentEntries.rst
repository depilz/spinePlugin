===========================
slot:getAttachmentEntries()
===========================

| **Type:** ``function``

Overview
--------

Returns entries containing usable skin lookup keys and their attachment objects.

Syntax
------

.. fragment: syntax lines; slot and skin are placeholders
.. code-block:: lua

   local effective = slot:getAttachmentEntries()
   local effective = slot:getAttachmentEntries(nil)
   local specific = slot:getAttachmentEntries("gold")
   local specific = slot:getAttachmentEntries(skin)

Parameters
----------

- ``skin`` *(optional)*:
    ``string`` or ``Skin`` – The skin to list. Omitted or ``nil``, searches the current skin then the default
    skin, including each lookup key once; current-skin entries override default entries with the same key.
    With a skin name or a Skin object, lists only that skin; an unknown name, a wrong type or a skin of other
    skeleton data raises. A name finds only the skeleton data's skins, so a skin made with
    ``skeleton:createSkin()`` must be passed as the Skin object.

Return value
------------

A valid skin with no entries, or no available current/default skin, returns ``{}``.
Array ordering is unspecified.

Each entry contains:

- ``slotName``: the name of this slot.
- ``placeholder``: the lookup key (skin placeholder name), which can differ from the object's name.
- ``skinName``: the source skin's name.
- ``attachment``: an :doc:`attachment object </api_reference/attachment/index>`.

Example
-------

.. code-block:: lua

   local slot = spineboy:getSlot("front-fist")
   for _, entry in ipairs(slot:getAttachmentEntries()) do
       print(entry.placeholder, entry.attachment.name, entry.skinName)
   end

See :doc:`/attachments-and-skins` for lookup, sharing, and animation behavior.
