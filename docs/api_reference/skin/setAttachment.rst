===================================
skin:setAttachment()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getAttachment`, :doc:`removeAttachment`

Overview:
.........

Copies an attachment into the skin under a lookup key. The key can differ from
``attachment.name``. This changes the mapping, not the currently displayed slot
attachment. Only ``nil`` removes the entry; invalid values raise a Lua error.
Attachments and source skins must come from the same skeleton data.

Sets an attachment in the skin. This allows you to add or replace attachments in a custom skin. Optionally, you can provide a source skin to copy bones and constraints from.

Syntax:
--------

.. code-block:: lua

   local success = skin:setAttachment(slotIndex, attachmentName, attachment, [sourceSkin])
   -- or using slot name
   local success = skin:setAttachment(slotName, attachmentName, attachment, [sourceSkin])

Parameters:
-----------

- ``slotIndex`` (number) or ``slotName`` (string) – The zero-based slot index or slot name
- ``attachmentName`` (string) – The name to give this attachment in the skin
- ``attachment`` (attachment object or nil) – The attachment to set, or ``nil`` to remove
- ``sourceSkin`` (skin object or string, optional) – Source skin to copy bones/constraints from

Returns:
--------

``boolean`` – Returns ``true`` if successful, ``false`` if the slot or source skin was not found or invalid. A warning message starting with ``"WARNING: "`` is printed to stderr on failure.

Example:
--------

Build Custom Skin
.................

.. code-block:: lua

   local customSkin = skeleton:createSkin("myCharacter")
   
   -- Get attachments from existing skins
   local currentSkin = assert(skeleton:getSkin(), "Apply a source skin first")
   local hatAttachment = currentSkin:getAttachment("head", "wizard-hat")
   local bodyAttachment = currentSkin:getAttachment("torso", "armor")
   
   -- Set them in custom skin (by slot index)
   customSkin:setAttachment(0, "wizard-hat", hatAttachment)
   customSkin:setAttachment(1, "armor", bodyAttachment)
   
   -- Or by slot name
   customSkin:setAttachment("head", "wizard-hat", hatAttachment)
   customSkin:setAttachment("torso", "armor", bodyAttachment)
   
   skeleton:setSkin(customSkin)

Remove Attachment
.................

.. code-block:: lua

   local skin = skeleton:createSkin("modified")
   skin:copySkin("default")
   
   -- Remove an attachment by passing nil
   skin:setAttachment("weapon-slot", "sword", nil)

Copy with Source Skin
......................

.. code-block:: lua

   local customSkin = skeleton:createSkin("advanced")
   local sourceSkin = skeleton:getSkin()
   
   -- Get attachment from source
   local attachment = sourceSkin:getAttachment("body", "special-mesh")
   
   -- Set it with source skin to preserve bones and constraints
   customSkin:setAttachment("body", "special-mesh", attachment, sourceSkin)
   
   -- Or pass source skin name as string
   customSkin:setAttachment("body", "special-mesh", attachment, "default")

Mix and Match System
....................

.. code-block:: lua

   local function createCustomCharacter(parts)
       local customSkin = skeleton:createSkin("custom")
       
       for slotName, attachmentName in pairs(parts) do
           -- Find attachment in any skin
           local skins = skeleton:getSkins()
           
           for _, skinName in ipairs(skins) do
               local skin = skeletonData:findSkin(skinName)
               local attachment = skin:getAttachment(slotName, attachmentName)
               
               if attachment then
                   customSkin:setAttachment(slotName, attachmentName, attachment, skin)
                   break
               end
           end
       end
       
       return customSkin
   end
   
   local mySkin = createCustomCharacter({
       ["head"] = "elf-head",
       ["body"] = "knight-armor",
       ["legs"] = "running-shoes"
   })
   
   skeleton:setSkin(mySkin)

Notes:
--------

- The attachment is copied (not just referenced) when set
- Both slot index (number) and slot name (string) are supported for the slot parameter
- Pass ``nil`` as the attachment to remove it (equivalent to :doc:`removeAttachment`)
- The ``sourceSkin`` parameter ensures bones and constraints are preserved for complex attachments
- Source skin can be a skin object or a skin name (string)
- Returns ``false`` and prints a warning instead of throwing an error when the slot or source skin is not found
- Check the return value to handle cases where the slot or skin might not exist

