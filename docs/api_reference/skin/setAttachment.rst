===================================
skin:setAttachment()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getAttachment`, :doc:`removeAttachment`, :doc:`../attachment/copy`

Overview:
.........

Puts an attachment into the skin under a lookup key. The key can differ from
``attachment.name``. This changes the mapping, not the currently displayed slot
attachment. Only ``nil`` removes the entry; invalid values raise a Lua error.
Attachments and source skins must come from the same skeleton data.

The skin **shares** the attachment object you pass: it is not copied, so a later
change to that object (its color or geometry) shows everywhere the object is used.
Use :doc:`../attachment/copy` first when this skin needs its own object.

Optionally, you can provide a source skin to copy bones and constraints from.

Syntax:
--------

.. code-block:: lua

   skin:setAttachment(slot, attachmentName, attachment, [sourceSkin])

Parameters:
-----------

- ``slot`` (string or Slot) – The slot name, or a Slot object of the same skeleton data. A number raises.
- ``attachmentName`` (string) – The lookup key to give this attachment in the skin. An empty string raises.
- ``attachment`` (attachment object or nil) – The attachment to set, or ``nil`` to remove
- ``sourceSkin`` (skin object or string, optional) – Source skin to copy bones/constraints from

Returns:
--------

``Skin`` – The skin itself, so calls can be chained.

Errors:
-------

Raises a Lua error, and changes nothing, when:

- the skin is a data skin (it is read-only; see :doc:`index`)
- the slot or the source skin is not found, or has the wrong type
- the attachment or the source skin belongs to different skeleton data

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
   
   customSkin:setAttachment("head", "wizard-hat", hatAttachment)
             :setAttachment("torso", "armor", bodyAttachment)
   
   skeleton:setSkin(customSkin)

Remove Attachment
.................

.. code-block:: lua

   local skin = skeleton:createSkin("modified")
   skin:copySkin("default")
   
   -- Remove an attachment by passing nil
   skin:setAttachment("weapon-slot", "sword", nil)

Own Copy of an Attachment
.........................

.. code-block:: lua

   local skin = skeleton:createSkin("tinted")
   local hat = skeleton:findSkin("default"):getAttachment("head", "hat")

   -- Tint only this skin's hat; the "default" skin keeps its color
   local myHat = hat:copy()
   myHat.color = {r = 1, g = 0.5, b = 0.5, a = 1}
   skin:setAttachment("head", "hat", myHat)

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
               local skin = skeleton:findSkin(skinName)
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

- The attachment is shared, not copied; use :doc:`../attachment/copy` for a separate object
- The slot is a slot name or a Slot object; a string is always a slot name, and a number raises
- Pass ``nil`` as the attachment to remove it (equivalent to :doc:`removeAttachment`)
- The ``sourceSkin`` parameter ensures bones and constraints are preserved for complex attachments
- Source skin can be a skin object or a skin name (string)
- **Skin bones.** Without ``sourceSkin``, this skin does not enable the skin bones the attachment's
  skin brings. On a slot whose bone is a skin bone the applied skin does not enable, the slot still
  shows the attachment but it is not updated and not drawn, and nothing raises. Pass the attachment's
  skin as ``sourceSkin`` (or apply that skin) to draw it.
