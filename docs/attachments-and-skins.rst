Attachments and skins
=====================

A slot holds one attachment object, or ``nil``. A skin maps a slot and a lookup
name to an attachment object. Changing a skin entry changes that mapping;
assigning an attachment to a slot changes what is displayed now.

The examples use the mix-and-match example skeleton. Its skins each dress one part of the character
(``skin-base``, ``eyes/green``, ``hair/pink``, ``accessories/hat-red-yellow``, ...), and its ``blink``
animation keys the eye slots.

Names and skin placeholders
---------------------------

The lookup name is the skin placeholder name when a placeholder was used in
Spine. It need not match ``attachment.name`` or the atlas texture path. For
example, the slot ``eye-front-iris`` has the lookup key ``eye-front-iris`` in two skins:
``eyes/green`` maps it to the object ``boy/eye-iris-front``, and ``eyes/violet`` maps it to
``girl/eye-iris-front``. Code and animation timelines request ``eye-front-iris`` in both cases.

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   girl:setSkin("eyes/violet")
   print(girl:getSlot("eye-front-iris").attachment.name)  -- girl/eye-iris-front

   girl:setSkin("eyes/green")
   girl:setAttachment("eye-front-iris", "eye-front-iris")
   -- Equivalent string lookup:
   girl:getSlot("eye-front-iris").attachment = "eye-front-iris"
   print(girl:getSlot("eye-front-iris").attachment.name)  -- boy/eye-iris-front

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

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))
   girl:setSkin("full-skins/girl")

   local slot = girl:getSlot("mouth")
   for _, entry in ipairs(slot:getAttachmentEntries()) do
       print(entry.placeholder, entry.attachment.name, entry.skinName)
       -- entry.placeholder is the lookup key; entry.attachment is the actual object.
   end

``slot:getSkinAttachments()`` lists only objects in the currently applied skin
(or default skin if none is applied). It does not merge default entries.
``slot:getAttachments()`` lists objects from all of the skeleton data's skins, possibly
with duplicates, and does not include custom skins. :doc:`api_reference/skin/getAttachments`
lists a skin's entry records (``slotName``, ``placeholder``, ``attachment``).

Direct ``slot.attachment = object`` assignment bypasses lookup. Objects must
come from the same skeleton data and should be authored for the destination slot;
sharing skeleton data alone does not make arbitrary weighted meshes interchangeable.
``slot:setAttachmentFromSkin(skinName, key)`` selects from exactly that skin without
changing the applied skin or enabling that skin's required bones and constraints.

Data skins and custom skins
---------------------------

Skins loaded with the skeleton data (**data skins**, from :doc:`api_reference/skeleton/findSkin` or
applied by name) are read-only: every skin mutator (``addSkin``, ``copySkin``, ``setAttachment``,
``removeAttachment``, ``clear``) and every skin color write raises
``Skin '<name>' is read-only (a data skin); use skeleton:createSkin() for a mutable skin``.
Build changes in a **custom skin** from :doc:`api_reference/skeleton/createSkin`. A custom skin is
applied with its Skin object, not by name.

Arguments and errors
--------------------

Skin methods take a slot as a slot name or a Slot object, and a skin as a skin name
or a Skin object, of the same skeleton data. A string is always looked up as a name, even
a numeric one: ``"1"`` is the skin or slot named ``1``. A Lua number raises. Entry records
name their slot with ``slotName``.

A call that cannot do what was asked raises a Lua error and changes nothing: an unknown
slot or skin, a wrong type, another skeleton data's slot, skin or attachment, a read-only
skin. Only :doc:`api_reference/skin/getAttachment` returns ``nil``, for a missing entry.
Use :doc:`api_reference/skeleton/findSkin` to check a skin name first: it returns ``nil``
for an unknown name. Mutators return the skin itself, so calls can be chained. The
:doc:`api_reference/skin/index` page lists the rule and the error messages.

Composing outfits
-----------------

A skeleton has one applied skin. Combine item skins into a custom skin when an
outfit needs multiple parts, retaining their lookup keys and skin-required bones
and constraints. Later additions replace earlier entries with the same slot/key.

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local outfit = girl:createSkin("outfit")
   outfit:addSkin("skin-base")
         :addSkin("eyes/green")
         :addSkin("hair/pink")
         :addSkin("clothes/hoodie-orange")
         :addSkin("legs/boots-red")
         :addSkin("accessories/hat-red-yellow")
   girl:setSkin(outfit)

**Compose every key your animations use.** Animations do not name attachment objects:
an attachment key in an animation requests a lookup key, resolved through the applied
skin (then the default skin) when the animation applies it. A key the composed skin does
not hold shows nothing. The ``blink`` animation keys ``eye-front-iris``: a skin built without
an ``eyes/...`` part leaves that slot empty whenever ``blink`` shows the iris.

Build the outfit before applying it. If you later change its required bones or
constraints, reapply it to refresh the skeleton's update cache. An applied
custom skin is retained automatically.

Rebuilding a skin in place
--------------------------

To change an outfit, rebuild the same custom skin: :doc:`api_reference/skin/clear` empties it
(entries, bones and constraints), add the parts again, then apply it again with ``setSkin``.
Reapplying refreshes the bones and constraints the skin enables and resets the slots (see
below). Creating a new skin for every change is equally correct, but each old skin's native
memory is freed only when Lua's garbage collector collects its wrapper, and the collector does
not see that memory: a rebuild per tap can pile up dead skins. ``clear()`` avoids that.

A per-character avatar recipe
.............................

Add the parts in a fixed order, from a constant list with ``ipairs``: where two parts define
the same slot/key, the later part wins, so put the part that should own a shared key
last. Iterating a table of parts with ``pairs`` gives no defined order. Saved part names
can be stale: check them with ``findSkin`` and fall back instead of raising.

.. code-block:: lua

   local ORDER = { "nose", "eyes", "hair", "clothes", "legs", "accessories" }
   local skinOf = setmetatable({}, { __mode = "k" })  -- one custom skin per skeleton

   local function applyAvatar(obj, parts)
       local skin = skinOf[obj]
       if skin then
           skin:clear()
       else
           skin = obj:createSkin("avatar")
           skinOf[obj] = skin
       end
       skin:addSkin("skin-base")
       for _, part in ipairs(ORDER) do
           local name = parts[part]
           if name and obj:findSkin(name) then
               skin:addSkin(name)
           end
       end
       obj:setSkin(skin)
   end

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))
   applyAvatar(girl, { eyes = "eyes/violet", hair = "hair/pink", legs = "legs/boots-red" })
   applyAvatar(girl, { eyes = "eyes/green", hair = "hair/short-red", accessories = "accessories/hat-pointy-blue-yellow" })

Tints set from Lua (``slot.color``, ``slot.alpha``) survive ``setSkin`` and animations: set
them when the colors change, not after every rebuild.

Switching skins and animation control
-------------------------------------

``skeleton:setSkin(skin)`` applies the skin and resets slots to setup pose. This
resets attachments, the Spine slot colors and dark colors (the colors the animations
key), and draw order, including manually changed slots. The tint written from Lua with
``slot.color`` or ``slot.alpha`` is the plugin's own and is not reset.
``skeleton:setSkin(skin, false)`` skips that extra reset and uses Spine's normal
skin-switch behavior: attachments matching the old skin can still be replaced by
matching entries in the new skin. It does not freeze every slot.

**Skin bones.** A skin can enable bones and constraints that exist only while it is
applied. After ``setSkin``, a slot whose bone is a skin bone the applied skin does not
enable does not raise when it still shows an attachment: the attachment is not updated
and not drawn. Apply a skin that enables the bone, or build the custom skin with the
part's skin (``addSkin``, or ``skin:setAttachment`` with its ``sourceSkin``); see
:doc:`api_reference/skeleton/setSkin`.

Animations can subsequently change attachments during ``updateState()``. For
manual overrides, use the frame order below:

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))
   girl:setSkin("eyes/green")
   girl:setAnimation(1, "blink", true)
   local selectedAttachment = girl:findSkin("eyes/yellow"):getAttachment("eye-front-iris", "eye-front-iris")

   -- every frame:
   girl:updateState(1000 / 60)
   girl:getSlot("eye-front-iris").attachment = selectedAttachment
   girl:draw()

Hiding or forcing an attachment
-------------------------------

The plugin has no attachment lock: an animation can always change a slot's attachment.
Pick one of these instead.

**(a) Hide a slot persistently: set its alpha to 0.** ``slot.alpha = 0`` survives
``setSkin``, ``setToSetupPose`` and animations, and the slot draws no geometry. The slot
still holds its attachment, so bounds, bounding boxes and ``computeWorldVertices`` still see
it, and an object :doc:`injected <api_reference/skeleton/inject>` on that slot is still
placed. ``slot.alpha`` is also your fade channel: save it and restore it when you show the
slot again.

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))
   girl:setSkin("full-skins/girl")

   local hat = girl:getSlot("hat")
   local savedAlpha = hat.alpha
   hat.alpha = 0              -- hidden, whatever the animations and skins do
   hat.alpha = savedAlpha     -- shown again

**(b) Hide or replace what animations request: compose a custom skin.** Leave the key out of
the custom skin to hide it, or map the key to another attachment to replace it
(``skin:setAttachment(slot, key, attachment)``). This is Spine's own mechanism: the
animation resolves the key through the skin every time it applies it, and a replacement made
with ``attachment:copy()`` of a keyed mesh still follows the animation's deform keys. It
cannot replace a key the animation sets to *no attachment*: that key does not go through
the skin.

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local yellowIris = girl:findSkin("eyes/yellow"):getAttachment("eye-front-iris", "eye-front-iris")
   local skin = girl:createSkin("odd-eyes")
   skin:addSkin("full-skins/girl")
       :setAttachment("eye-front-iris", "eye-front-iris", yellowIris)  -- replace
       :removeAttachment("eye-back-iris", "eye-back-iris")             -- hide
   girl:setSkin(skin)
   girl:setAnimation(1, "blink", true)

**(c) Keep a slot showing an attachment while the animation hides or switches it: set it
after every** ``updateState``, as in the frame order above. This is exact for a plain region.
For a mesh with deform keys, or an attachment with a sequence, the frames where the
animation keys another attachment (or none) lose the override's deform and sequence frame.

Sharing, copying, and lifetime
------------------------------

``addSkin`` shares attachment objects. Changing an object's color or geometry can
affect other skins and skeletons that share it. Prefer slot color for per-instance
tinting. ``skin.color`` is editor metadata and does not tint rendered attachments.

``copySkin`` creates separate attachment objects, but meshes use Spine linked-mesh
semantics: texture resources and deformation/timeline relationships are not fully
independent. ``skin:setAttachment(slot, key, object)`` shares the object, like
``addSkin``; call :doc:`attachment:copy() <api_reference/attachment/copy>` first for a
separate one. Only ``nil`` removes an entry; invalid values raise an error without
deleting it. Editing a mapping does not immediately replace an attachment already
displayed by a slot.

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local iris = girl:findSkin("eyes/green"):getAttachment("eye-front-iris", "eye-front-iris")
   local redIris = iris:copy()
   redIris.color = { r = 1, g = 0.3, b = 0.3, a = 1 }  -- the "eyes/green" skin keeps its color

   local skin = girl:createSkin("red-eyes"):addSkin("full-skins/girl")
   skin:setAttachment("eye-front-iris", "eye-front-iris", redIris)
   girl:setSkin(skin)

Applied custom skins, displayed attachments, Lua attachment wrappers, and linked
mesh dependencies retain their native resources. Retained skin/attachment wrappers
remain usable after a skeleton is removed. Wrappers that belong to the skeleton
(slots, bones, IK and physics constraints, track entries, fills and effects) raise
``<Type> belongs to a removed skeleton`` instead; see :doc:`lifecycle`.

Skins on a split skeleton
-------------------------

Skin, attachment, animation and draw-order changes on a :doc:`split <api_reference/skeleton/split>`
skeleton take effect on its next draw, in whichever group each slot is drawn. The split group
is yours to place, and its lifetime works like this:

- :doc:`api_reference/skeleton/reassemble` moves everything back into the skeleton, including
  injected objects whose split slot is hidden at that moment, then removes the split group.
- :doc:`api_reference/skeleton/removeSelf` removes only the meshes the skeleton drew into the
  split group; the group itself stays yours to remove.
- If you remove the split group (or its parent), the skeleton treats it as reassembled: the next
  draw puts every slot back in the skeleton, and the next ``split()`` makes a new group.
  Injected objects inside the removed group are removed with it.

Exporting art
-------------

- **Export atlases with straight alpha.** Leave "Premultiply alpha" off when you pack the
  atlas: Solar2D premultiplies textures when it loads them. :doc:`api_reference/spine/loadAtlas`
  prints a warning for an atlas page with ``pma: true``.
- **Tint black has limits.** The effect name ``filter.custom.plugin_spine_tintBlack`` is
  reserved for the plugin. While ``skeleton.fill.effect`` is set (for example a hit flash), no
  slot of that skeleton draws its dark color: a fill effect and tint black cannot be combined.
  See :doc:`api_reference/skeleton/fill/effect`.

.. note::

   **Clipping edges and anti-aliasing.** Clipping attachments cut images with hard polygon
   edges; in the Spine editor they look smooth only when its MSAA setting is on. Solar2D
   ignores ``antialias`` in ``config.lua`` and reads only ``multisample``, and on iOS
   ``multisample`` has no effect. This note comes from reading the Solar2D source; the plugin's
   tests do not measure it.

See Spine's `Runtime Skins guide <https://esotericsoftware.com/spine-runtime-skins>`_
for the underlying model.
