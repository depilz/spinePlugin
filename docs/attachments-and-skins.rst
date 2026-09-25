Attachments and skins
=====================

A slot holds one attachment object, or ``nil``. A skin maps a slot and a lookup
name to an attachment object. Changing a skin entry changes that mapping;
assigning an attachment to a slot changes what is displayed now.

Names and skin placeholders
---------------------------

The lookup name is the skin placeholder name when a placeholder was used in
Spine. It need not match ``attachment.name`` or the atlas texture path. For
example, the slot ``based_rank_medal`` can have lookup key ``medal`` in two skins:
``bronze`` maps it to the object ``based/rank1_medal``, and ``gold`` maps it to
``based/rank3_medal``. Code and animation timelines request ``medal`` in both cases.

.. code-block:: lua

   skeleton:setSkin("gold")
   skeleton:setAttachment("based_rank_medal", "medal")
   -- Equivalent string lookup:
   skeleton:getSlot("based_rank_medal").attachment = "medal"

Both string setters search the current skin first, then the default skin if the
key is missing. They raise a Lua error if lookup fails, leaving the slot unchanged.
Use ``nil`` to clear a slot. The string ``"null"`` is a literal lookup key, not a
special clear command.

Attachments not assigned to an editor skin are stored in the runtime's default
skin. A skeleton may display default attachments while ``skeleton:getSkin()``
returns ``nil``: that method reports the explicitly applied skin.

Inspecting and selecting attachments
------------------------------------

Use :doc:`api_reference/skeleton/slot/getAttachmentEntries` for names that can
be used in lookup calls. Without a skin name, it lists the effective current-plus-
default entries, with current-skin entries taking precedence.

.. code-block:: lua

   local slot = skeleton:getSlot("based_rank_medal")
   for _, entry in ipairs(slot:getAttachmentEntries()) do
       print(entry.name, entry.attachment.name, entry.skinName)
       -- entry.name is the lookup key; entry.attachment is the actual object.
   end

``slot:getSkinAttachments()`` lists only objects in the currently applied skin
(or default skin if none is applied). It does not merge default entries.
``slot:getAttachments()`` lists objects from all registered skins, possibly with
duplicates, and does not include unregistered custom skins.

Direct ``slot.attachment = object`` assignment bypasses lookup. Objects must
come from the same skeleton data and should be authored for the destination slot;
sharing skeleton data alone does not make arbitrary weighted meshes interchangeable.
``slot:setAttachmentFromSkin(skinName, key)`` selects from exactly that skin without
changing the applied skin or enabling that skin's required bones and constraints.

Switching skins and animation control
-------------------------------------

``skeleton:setSkin(skin)`` applies the skin and resets slots to setup pose. This
resets attachments, slot colors, and draw order, including manually changed slots.
``skeleton:setSkin(skin, false)`` skips that extra reset and uses Spine's normal
skin-switch behavior: attachments matching the old skin can still be replaced by
matching entries in the new skin. It does not freeze every slot.

Animations can subsequently change attachments during ``updateState()``. For
manual overrides, use the frame order below:

.. code-block:: lua

   skeleton:updateState(deltaMilliseconds)
   skeleton:getSlot("based_rank_medal").attachment = selectedAttachment
   skeleton:draw()

Alternatively, ``slot.attachmentLocked = true`` blocks the plugin's animation-state
attachment changes for that slot. It does not block direct assignments, skin
switches, or explicit setup-pose resets. Unlock it to resume animation control.

Composing outfits
-----------------

A skeleton has one applied skin. Combine item skins into a custom skin when an
outfit needs multiple parts, retaining their lookup keys and skin-required bones
and constraints. Later additions replace earlier entries with the same slot/key.

.. code-block:: lua

   local outfit = skeleton:createSkin("outfit")
   assert(outfit:addSkin("body"))
   assert(outfit:addSkin("shirt"))
   assert(outfit:addSkin("medals/gold"))
   skeleton:setSkin(outfit)

Build the outfit before applying it. If you later change its required bones or
constraints, reapply it to refresh the skeleton's update cache. Registration is
only needed for lookup by name; an applied custom skin is retained automatically.
``registerSkin`` changes shared skeleton data, rejects a conflicting name, and
only accepts a skin from the same skeleton data.

Sharing, copying, and lifetime
------------------------------

``addSkin`` shares attachment objects. Changing an object's color or geometry can
affect other skins and skeletons that share it. Prefer slot color for per-instance
tinting. ``skin.color`` is editor metadata and does not tint rendered attachments.

``copySkin`` creates separate attachment objects, but meshes use Spine linked-mesh
semantics: texture resources and deformation/timeline relationships are not fully
independent. ``skin:setAttachment(slot, key, object)`` preserves this plugin's
existing copy-on-insertion behavior. Only ``nil`` removes an entry; invalid values
raise an error without deleting it. Editing a mapping does not immediately replace
an attachment already displayed by a slot.

Applied custom skins, displayed attachments, Lua attachment wrappers, and linked
mesh dependencies retain their native resources. Retained skin/attachment wrappers
remain usable after a skeleton is removed; slot access then raises an error.

Lua arrays and track indexes are one-based. For compatibility, numeric slot indexes
in skin methods and entry records are **zero-based**. Prefer slot names in skin
methods to avoid mixing these conventions.

See Spine's `Runtime Skins guide <https://esotericsoftware.com/spine-runtime-skins>`_
for the underlying model.
