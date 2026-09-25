===================================
slot.attachmentLocked
===================================

| **Type:** ``boolean``
| **See also:** :doc:`index`, :doc:`attachment`

Overview:
.........

Gets or sets whether animations can change this slot's attachment. When ``true``, 
animations will not modify this slot's attachment, allowing you to manually control 
the attachment without it being overridden by animation playback.

This is useful when you want to:

- Programmatically swap attachments while animations are playing
- Clear an attachment (set to ``nil``) and keep it cleared
- Mix attachments from different skins during animation playback

Syntax:
--------

**Reading:**

.. code-block:: lua

   local isLocked = slot.attachmentLocked  -- Returns true or false

**Writing:**

.. code-block:: lua

   slot.attachmentLocked = true   -- Lock the slot (animations won't change it)
   slot.attachmentLocked = false  -- Unlock the slot (normal behavior)

Example:
--------

**Manually Control Attachment During Animation:**

.. code-block:: lua

   local slot = hero:getSlot("weapon")
   
   -- Lock the slot so animations don't change the attachment
   slot.attachmentLocked = true
   
   -- Now you can set any attachment and it will stay
   slot.attachment = nil  -- Clear it
   -- or
   slot.attachment = customWeaponAttachment  -- Set a custom one
   
   -- Play an animation - it won't override our attachment choice
   hero:setAnimation(1, "attack", false)

**Unlock to Restore Animation Control:**

.. code-block:: lua

   local slot = hero:getSlot("weapon")
   
   -- Lock and set custom attachment
   slot.attachmentLocked = true
   slot.attachment = nil
   
   -- Later, unlock to let animations control it again
   slot.attachmentLocked = false
   
   -- Call setToSetupPose to restore the default attachment
   hero:setToSetupPose()

Notes:
------

- Default value is ``false`` (animations can change the attachment)
- The lock only affects attachment changes from animations, not from direct assignment via ``slot.attachment``
- The lock persists until you explicitly set it back to ``false``
- Locking does not affect other slot properties like color

