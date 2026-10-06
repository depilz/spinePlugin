===================================
skin:removeAttachment()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setAttachment`, :doc:`getAttachment`

Overview
--------

Removes an attachment from the skin by slot and attachment name.

Syntax
------

.. fragment: syntax line; skin, slot and attachmentName are placeholders
.. code-block:: lua

   skin:removeAttachment(slot, attachmentName)

Parameters
----------

- ``slot`` *(required)*:
    ``string`` or ``Slot`` – The slot name, or a Slot object of the same skeleton data. A number raises.
    A Slot of a removed skeleton raises.
- ``attachmentName`` *(required)*:
    ``string`` – The name of the attachment to remove.

Return value
------------

``Skin`` – The skin itself, so calls can be chained.

Raises a Lua error, and changes nothing, when this skin is a data skin (read-only), or when the
slot is not found or has the wrong type.

Example
-------

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

Remove Specific Attachments
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local customSkin = girl:createSkin("custom")
   customSkin:copySkin("full-skins/girl")

   -- Remove an unwanted attachment
   customSkin:removeAttachment("hat", "hat")

   girl:setSkin(customSkin)

Clean Up Skin
~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local skin = girl:createSkin("cleaned")
   skin:addSkin("full-skins/girl")

   -- Remove the hat and its pompom (slot, key)
   local accessories = { {"hat", "hat"}, {"pompom", "pompom"} }
   for _, entry in ipairs(accessories) do
       skin:removeAttachment(entry[1], entry[2])
   end

Notes
-----

- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- Does nothing if the attachment is not found
- To add back an attachment, use :doc:`setAttachment`
- Raises on a data skin: data skins are read-only (see :doc:`index`)
- To remove every entry at once, use :doc:`clear`
