# Changelog

## plugin.spine43 3.0.1

A patch release of the Spine 4.3 line: `plugin.spine43` 3.0.0 plus the fix below. Tested on the Mac Simulator only;
other platforms are assumed to behave the same.

### Fixed

- **A skeleton draws in the same place whatever default anchor the app sets.** The plugin draws a skeleton with
  meshes, and each new mesh took the app's `display.setDefault("anchorX", …)` and `display.setDefault("anchorY", …)`,
  so with any default other than 0.5 the skeleton drew shifted (with defaults of 0, right and down by half its size).
  Each mesh now gets anchor 0.5 when the plugin creates it, so a skeleton, its split groups and the attachments it
  draws after a default change stay in place. If your app moved its skeletons to make up for the shift, remove that
  offset. Setting the default anchor back to 0.5 around `draw()` stays harmless, so that workaround can stay or go.
  `plugin.spine` 1.2.6 gets no fix (there is no 1.2.7): use that workaround there.

## plugin.spine42 2.0.1

A patch release of the Spine 4.2 line: `plugin.spine42` 2.0.0 plus the fix below and the shared changes
`plugin.spine43` 3.0.0 already has. Tested on the Mac Simulator only; other platforms are assumed to behave the same.

### Fixed

- **A skeleton draws in the same place whatever default anchor the app sets.** The plugin draws a skeleton with
  meshes, and each new mesh took the app's `display.setDefault("anchorX", …)` and `display.setDefault("anchorY", …)`,
  so with any default other than 0.5 the skeleton drew shifted (with defaults of 0, right and down by half its size).
  Each mesh now gets anchor 0.5 when the plugin creates it, so a skeleton, its split groups and the attachments it
  draws after a default change stay in place. If your app moved its skeletons to make up for the shift, remove that
  offset. Setting the default anchor back to 0.5 around `draw()` stays harmless, so that workaround can stay or go.
  `plugin.spine` 1.2.6 gets no fix (there is no 1.2.7): use that workaround there.

### Shared changes from plugin.spine43 3.0.0

These were in the tree both lines build from when `plugin.spine43` 3.0.0 was released, after `plugin.spine42` 2.0.0.
`plugin.spine42` ships them from 2.0.1.

- **A split mesh whose `removeSelf` raises no longer leaks.** When a skeleton is removed, it removes its split
  meshes. If a `removeSelf` you gave a split mesh raised there, the error reached the caller but the plugin kept a
  reference to the mesh forever; it now releases the mesh first.
- **The tint-black source comment states the one-Spine-plugin-per-app rule.** Comment only; no behaviour change.
- **A skeleton's data keeps a pointer to the atlas it was loaded with.** Internal, for `copy{ region }` and
  `createAttachment` on the 4.3 line; no behaviour change on the 4.2 line.
- **Android builds are the same bytes from any checkout path.** The Android native build compiles with
  `-ffile-compilation-dir=.`, so the `.so` no longer records the path of the checkout it was built in.

## plugin.spine43 3.0.0

The Spine 4.3 line, published as `plugin.spine43`. Every entry is written for a project that uses `plugin.spine42`
2.0.0: "Breaking" marks a change that code written for 2.0.0 may need to follow, and the migration page of the
documentation shows each one.

- **The shared changes released under "Both lines" in plugin.spine42 2.0.0 below apply to `plugin.spine43` (version
  3.0.0) too.** The 4.3 line reads only skeleton data exported by Spine 4.3: re-export your skeletons with Spine 4.3.
- **The Spine runtime is frozen at spine-ts-4.3.13; export with Spine 4.3.75-beta or older.** The vendored runtime is
  spine-cpp as of upstream tag `spine-ts-4.3.13` (`b7beb2ccb`), with the plugin's own runtime changes. Every example
  the line is tested with was exported by Spine 4.3.75-beta; data from a newer 4.3 editor is not tested.
- **Breaking: `trackEntry.holdPrevious` is removed.** Spine 4.3 has no hold-previous flag: its runtime always holds
  the previous entry during a mix, as `holdPrevious = true` did. Reading or writing it raises
  `SpineTrackEntry: property 'holdPrevious' was removed in Spine 4.3; use additive or mixInterpolation`. Drop it;
  neither `trackEntry.additive` nor `trackEntry.mixInterpolation` (below) replaces it. The 4.2 line keeps
  `holdPrevious`.
- **Added `trackEntry.additive` and `trackEntry.mixInterpolation`.** `additive = true` makes an entry add its
  animation to the pose of the tracks below it instead of replacing it (`false` by default; no effect on track 1 at
  alpha 1). `mixInterpolation` is how the mix from the previous entry progresses: `"linear"` (the default),
  `"smooth"`, `"slowFast"`, `"fastSlow"` or `"circle"`; any other value raises
  `SpineTrackEntry: mixInterpolation must be one of 'linear', 'smooth', 'slowFast', 'fastSlow', 'circle'`.
- **Added `slot.appliedAttachment`.** The attachment the renderer draws for the slot, read-only. A slider constraint
  whose animation keys the slot's attachment changes only what is drawn, so it can differ from `slot.attachment`.
- **Added `skeleton.sliders`.** A read-only table of the skeleton's slider constraints by name. A slider's `time` and
  `mix` read and write; `duration`, `name`, `animation`, `loop` and `boneDriven` are read-only. Writing `time` on a
  bone-driven slider detaches it from its bone for good. A slider kept after its skeleton is removed raises
  `Slider belongs to a removed skeleton`. The 4.3 example project has a Sliders scene.
- **Added `attachment.region`, `attachment:copy{ region = … }` and `skeleton:createAttachment{ … }`.**
  `attachment.region` is the atlas region a region or mesh attachment shows, read-only. `copy{ region = "<name>" }`
  returns a copy that shows another region of the skeleton's own atlas. `createAttachment{ region = …, name = … }`
  creates a region attachment from it. A region the atlas does not have raises
  `Region not found in the skeleton's atlas: <name>`.
- **Physics rotation follows gravity and forces the right way on screen.** The vendored runtime now includes upstream
  spine-cpp `d6e239975` ("Fix Y-down physics constraint forces"). Physics constraints that rotate, shear or scale a bone
  under gravity or wind bent it the wrong way on screen, because the plugin runs Spine in Y-down mode; they now bend it
  as in the Spine editor. Content with non-zero gravity or wind on rotating physics constraints moves the other way than
  before.
- **One-bone IK on bones that don't inherit rotation or reflection points the right way.** The vendored runtime now
  includes upstream spine-cpp `37b4d7cdd` ("Fix Y-down IK inheritance"). A one-bone IK constraint on a bone whose
  transform mode is "only translation" or "no rotation or reflection" pointed about 180 degrees away from its target,
  because the plugin runs Spine in Y-down mode; it now points at the target as in the Spine editor.
- **Clipping masks match the Spine editor.** A clipping attachment on an inactive bone (a skin bone whose skin is not
  set) no longer clips the slots after it. A clip whose end slot holds a bounding box, point or path attachment now
  ends at that slot instead of clipping the rest of the draw order. On arm64 builds (iOS, Apple Silicon Mac, Android
  arm64) masks no longer drop whole pieces of a masked attachment or draw triangles outside the mask for single
  frames: the triangulator no longer uses fused multiply-add, so a mask no longer triangulates outside its outline.
- **`attachment.hullLength` counts numbers, not vertices.** The 4.3 runtime stores a mesh's hull as a count of
  numbers (x and y of each hull vertex), so the same mesh reads twice the 4.2 line's value, which counts vertices.
- **`ikConstraint.isActive` and `physics.isActive` read `false` for an inactive constraint.** Both always read `true`
  on the 4.3 line, because of a spine-cpp 4.3 runtime bug (also upstream): `Skeleton::updateCache` set a different
  active flag than the one `isActive()` reads. The vendored runtime is patched so every constraint type (IK, transform,
  path, physics, slider) has a single active flag. Behaviour change: animation timelines no longer change a constraint
  that is inactive (skin-required and not in the current skin), as on the 4.2 line and in the Spine editor. Before,
  they still keyed its mix and other pose values, and a physics timeline could reset it.

## plugin.spine42 2.0.0

The Spine 4.2 line, published as `plugin.spine42`, after the public `plugin.spine` 1.2.6. Every entry is written for
a project that uses 1.2.6: "Breaking" marks a change that code written for 1.2.6 may need to follow, and the
migration page of the documentation shows each one with code before and after. The entries under "Both lines" are
the shared Lua layer, which the 4.3 line (`plugin.spine43` 3.0.0, above) has too.

### Both lines

- **Breaking: the plugin is published once per Spine line.** `plugin.spine42` (version 2.0.0) runs Spine 4.2, the
  runtime line 1.2.6 runs, so skeletons exported for 1.2.6 load without a new export; `plugin.spine43` runs Spine 4.3
  with the same Lua API. The `plugin.spine` 1.2.x releases stay as they are. Moving from `plugin.spine` means renaming
  the plugin in `build.settings` and in every `require`. The load banner prints `v2.0.0`.
- **One Spine plugin per app.** Requiring `plugin.spine42` or `plugin.spine43` while the other line or the legacy
  `plugin.spine` is already loaded in the app raises
  `<plugin> cannot load: <other plugin> is already loaded in this app. Use only one Spine plugin per app.` before the
  plugin changes anything; requiring the same plugin again is fine. A legacy `plugin.spine` required after a line
  cannot check and is not caught.
- **The documentation has one version per line.** The 4.2 and 4.3 documentation each name their own plugin in
  every sample and link inside their own version; the 1.2 documentation stays for `plugin.spine`.
- **Breaking: `ikConstraint.isActive` and `physics.isActive` are read-only.** Writing either now raises
  `IK constraint isActive is read-only; set mix = 0 to stop it` or
  `Physics constraint isActive is read-only; set mix = 0 to stop it`. Before, the write was accepted, but Spine
  overwrote it the next time it rebuilt the skeleton's update order (on `setSkin`, for example), so it did not
  reliably stop the constraint. Reading `isActive` is unchanged. To stop a constraint, set its `mix` to `0`, as the error says.
- **Added `skeleton.physicsTimeScale`.** It scales the time step of the skeleton's Spine physics constraints: `1` by
  default, `0` pauses physics without a catch-up burst when it resumes. `timeScale` still does not affect physics.
  Writing a negative or non-finite value raises `physicsTimeScale must be a finite number >= 0`.
- **Breaking: removed skeletons are freed on the next frame, and objects you kept raise instead of reading freed
  memory.** `removeSelf()`, `display.remove()` and removing a parent group or a composer scene all take the same path:
  the skeleton stops updating, drawing and dispatching animation events at once, and a one-shot `Runtime`
  `enterFrame` listener frees its native memory on the next frame, so memory measured in the same frame still
  includes it. Bones, slots, constraints, fills, effects and track entries you kept keep working in the handler that
  removed the skeleton and in its `finalize` listeners; after that frame's finalize they raise
  `<Type> belongs to a removed skeleton`, and a skeleton method you stored raises
  `Skeleton belongs to a removed skeleton`. In 1.2.6 they kept returning the values the skeleton had when it was
  removed. A removed skeleton answers only its event-dispatcher keys (`addEventListener`, `removeEventListener`,
  `hasEventListener`, `dispatchEvent`, `respondsToEvent`, and the `getOrCreateTable`, `didRemoveListener` and
  `_setHasListener` helpers Solar2D's listener calls use) until the end of that frame's finalize; every other public
  key reads `nil`, including `removeSelf` and `numChildren`, so `if skeleton.removeSelf then` tells a removed skeleton
  from a live one. See the "Removing skeletons" page.
- **Breaking: `event.target` in animation events is the skeleton display object.** `event.target == skeleton` now
  holds; it used to be an internal userdata.
- **Added track-entry calls and keys.** `skeleton:addAnimationAt`, `skeleton:getTrackEntry`,
  `skeleton:setEmptyAnimations` and `skeleton:setListener` are new, and track entries gain `mixDuration`,
  `trackComplete`, `next`, `mixingFrom` and `mixingTo`. `addAnimationAt` on a playing track with a time at or before
  the start of the last queued entry starts the new entry on the update right after that entry starts.
- **Breaking: a finished track entry raises; added `entry.isValid`.** A track entry that has finished or was
  returned to the pool now raises `Track entry is no longer valid (finished or disposed); check entry.isValid`
  instead of reading pooled data or aliasing another entry. In 1.2.6 reading `.animation` from such an entry returned
  `nil`.
- **Animation listener errors are reported.** An error in the listener passed to `spine.create()` used to vanish; it
  now reaches the console and the `unhandledError` event like any other Solar2D listener error, and the call that
  triggered it carries on.
- **An IK target bone from another skeleton is rejected** with `target bone must belong to the same skeleton`.
- **Bad arguments raise instead of being misread.** `spine.create()` given an atlas instead of skeleton data raises
  an argument error instead of misreading it, and bad arguments to `spine.loadSkeletonData()` and
  `skeleton:inject()` no longer leak.
- **A fill used inside a coroutine no longer keeps the dead coroutine's state.**
- **The split group belongs to you, and the skeleton cleans up after itself in it.** Removing a split skeleton now
  takes the skeleton's meshes out of the group returned by `split()` and leaves the group where you put it; they used
  to stay on screen. `removeSelf()` and `display.remove()` take them out at once; when the skeleton goes with its
  parent group or scene, they leave when its memory is freed on the next frame. If you remove the
  split group yourself, the skeleton draws unsplit from the next `draw` and a later `split()` returns a new group;
  `reassemble()` after that no longer raises. `reassemble()` keeps an object injected
  into a split slot that is hidden at that moment, instead of destroying it with the group.
- **Breaking: injection listeners are called once per frame with the real visibility.** The listener passed to
  `skeleton:inject()` is now called once per `draw` with `isVisible = true` while its slot is drawn, once with
  `isVisible = false` on the frame its slot stops being drawn, and not at all while the slot stays hidden. It used to
  get an extra `isVisible = false` call before the `true` one on most frames, and in split mode on every frame. The
  event fields are unchanged.
- **`draw()` with extra arguments works.** It used to corrupt the Lua stack.
- **Meshes land in the right group and draw order after split, re-split, reassemble or injection.** A mesh reused from
  the skeleton group in the split group (or the other way round), or from another draw position, used to stay where it
  was, so pieces showed in the wrong group or on top of the wrong slots. It is now moved to its group and draw position.
- **A non-normal blend mode stays applied after a texture swap.** A slot drawn with `multiply`, `add` or `screen` used to
  fall back to normal blending when its mesh switched to another atlas page texture.
- **Mesh updates no longer create Lua garbage on every draw.** Updating a skeleton's meshes reuses one parameter table
  and its vertex buffers instead of allocating new ones per mesh per draw: for 150 copies of the Spine raptor example,
  Lua allocation drops from about 7.9 MB to about 0.27 MB per frame, together with batching (below; see "Performance on
  Mac").
- **Breaking: custom animation events have `name = "spine"` and `phase = "event"`, and carry the values of the key
  that fired.** Every animation event now has `event.name == "spine"`. A custom event keyed in Spine has
  `event.phase == "event"` and its name in `event.event`, plus `int`, `float`, `string`, `time`, `animation`,
  `trackIndex` and `target`, and `audioPath`, `volume` and `balance` when it has audio. It used to arrive with its
  name in `event.name` and no `phase`, so a listener that tells custom events apart with `event.name ~= "spine"` must
  check `event.phase == "event"` instead. A custom event named `"spine"` no longer looks like a lifecycle event.
  `event.int`, `event.float`, `event.string`, `event.volume` and `event.balance` are the values set on that key in
  the animation; they used to be the event's default values from the Spine editor for every key. The new
  `event.time` is the key's time in milliseconds. Lifecycle events are unchanged.
- **Breaking: `skeleton.isActive` is `true` only while a track has a current entry.** It becomes `false` after
  `clearTrack` on the last track that had an entry, and once an empty animation that mixes a track out has ended on
  every track. It used to stay `true` until `clearTracks`. Loops that call `updateState` and `draw` only while
  `isActive` is `true` stop updating such a skeleton earlier than before, and skip a skeleton with physics and no
  animation track.
- **Breaking: physics steps in `updateState`, and `draw` only poses.** `updateState` now steps the physics
  constraints and poses the skeleton, so bone and slot world values, `getBounds()` and `getSize()` are current after
  every `updateState`, and right after `spine.create()`. `updateState` advances physics even when no animation track
  exists, so a skeleton with physics and no animation simulates instead of standing still. `draw` poses without
  stepping physics, so bone changes made from Lua between `updateState` and `draw` are drawn, and physics reacts at
  the next `updateState`. With one `updateState` and one `draw` per frame nothing changes. Code that calls `draw`
  without `updateState`, `updateState` several times per `draw`, or `updateState` without `draw` (for example for
  off-screen skeletons) now moves physics once per `updateState` instead of once per `draw`.
- **Breaking: `skeleton.tracks` is a plain table.** Each read builds a new table where `tracks[i]` is the current
  track entry of track `i`, or `false` for an empty track, for every track up to the highest one used. `ipairs` and
  `#` now work on it, and `if tracks[i] then` keeps working. It used to be a proxy object that `ipairs` and `pairs`
  rejected.
- **Breaking: writing an unknown or read-only track-entry key raises.** `entry.foo = 1` raises
  `SpineTrackEntry: unknown property 'foo'`, and writing `index`, `animation`, `animationTime`, `isComplete`,
  `isValid`, `trackComplete`, `next`, `mixingFrom` or `mixingTo` raises
  `SpineTrackEntry: property '<key>' is read-only`. Both used to be ignored silently. Reading an unknown key still
  returns `nil`.
- **Breaking: `getSize().offsetY` is `getBounds().yMin`.** `(offsetX, offsetY)` is now the top-left corner of the bounds in
  the skeleton's y-down coordinates; `offsetY` used to be `-yMin`. `width`, `height` and `offsetX` are unchanged.
- **Added `skeleton:addEventListener("spine", listener)`.** The skeleton now dispatches every animation event to its
  own `"spine"` listeners, after the listener passed to `spine.create()` or `setListener`: function listeners, then
  table listeners, as Solar2D does for every event. All listeners get the same event table. Such listeners used to
  never fire. `setListener(nil)` clears only the `spine.create()` listener.
- **Added `entry.onComplete`.** A function set on a track entry is called with the `completed` event every time that
  entry completes, before the other listeners. It never fires after the skeleton was removed, and an entry reused
  from the pool starts without one.
- **`setEmptyAnimation` and `addEmptyAnimation` return their track entry.** They used to return nothing.
  `setEmptyAnimations` returns nothing.
- **Track entries compare with `==`.** Two track-entry objects are equal when they stand for the same entry, for
  example `skeleton:getTrackEntry(1) == skeleton.tracks[1]`. Comparing never raises.
- **Added `spine.version` and `spine.runtimeVersion`, without the `v` the load banner prints.**
  `spine.version` is the plugin version (`"2.0.0"` for `plugin.spine42`, `"3.0.0"` for `plugin.spine43`) and
  `spine.runtimeVersion` the Spine runtime line (`"4.2"` or `"4.3"`). The load banner prints `v2.0.0`, so
  code that compares `spine.version` with the banner's form must drop the `v`.
- **Load errors say why.** `spine.loadSkeletonData()` raises
  `Failed to load skeleton data: <path>: <reason>` with the Spine runtime's reason, for example a version mismatch.
  `spine.loadAtlas()` raises `Failed to load texture: <path>` with the error `graphics.newTexture` raised when a page
  texture cannot be loaded, and keeps nothing in memory.
- **Added `skeleton:hitTest(x, y[, listener])`.** It tells which bounding-box attachments contain a point given in
  content coordinates, last drawn first. Without a listener it returns the top-most hit table (`slotName`,
  `attachmentName`, `target`, `x`, `y`, `localX`, `localY`) or `nil`; with one it calls the listener for every hit
  until it returns `true`, and returns whether one did. Visibility and alpha do not affect it.
- **Added `bone:setWorldPosition`, `bone:translateWorld`, `bone:localToWorld` and `bone:worldToLocal`.** They move a
  bone to a position, or by an offset, in skeleton space and convert points between a bone's space and skeleton
  space. Skeleton space is the skeleton object's local coordinates, y down. A write shows in the world values after
  the next `updateState` or `draw`, and an animation keying the bone overwrites it.
- **Breaking: writing `bone.worldX` or `bone.worldY` raises.** The error is
  `worldX is read-only; use bone:setWorldPosition(x, y)` (or `worldY`). Such writes used to be ignored silently.
- **Tint black: art with dark colours now renders as in the Spine editor.** Slots with a dark colour (Spine's
  "Tint black", two-colour tint) other than black are drawn with it; 1.2.6 ignored the dark colour. This is a visible
  change for such art; skeletons without dark colours render as before. The plugin defines the Solar2D effect
  `filter.custom.plugin_spine_tintBlack` for this on first use; the name is reserved, so do not define it in your
  app. While `skeleton.fill.effect` is set, the skeleton draws without its dark colours, so a hit flash and tint black
  cannot combine; tint black is back on the next draw after the effect is cleared. A write through an effect table
  you kept from before `fill.effect = nil` sets an effect again and takes the place of tint black, like any effect.
  Export atlases with straight alpha. See the "skeleton.fill.effect and tint black" page.
- **Breaking: added `slot.darkColor`, read-only.** It returns the slot's dark colour as a new `{ r, g, b }` table
  (0 to 1), or `nil` for a slot without one. Writing it raises
  `SpineSlot: property 'darkColor' is read-only; the skeleton data and its animations set it`; such a write used to
  be ignored.
- **Added Skin and Attachment objects.** `skeleton:createSkin(name)` makes a custom skin, `skeleton:getSkin()` returns
  the applied skin, and `skeleton:setSkin` takes a skin name, a Skin object or `nil` (which clears the applied skin);
  an applied custom skin is retained automatically. A Skin has `name` and a colour (`r`, `g`, `b`, `a`, `color`), and
  `addSkin`, `copySkin`, `setAttachment`, `getAttachment`, `getAttachments`, `removeAttachment`, `clear`,
  `findAttachmentsForSlot`, `findNamesForSlot`, `getBones`, `getConstraints` and `getName`; slots gain
  `slot:setAttachmentFromSkin` and `slot:getAttachmentEntries`. Skin mutators and `slot:setAttachmentFromSkin` return
  their receiver, so calls can be chained. A skin loaded with the skeleton data is read-only: every mutator and every
  colour write raises `Skin '<name>' is read-only (a data skin); use skeleton:createSkin() for a mutable skin`.
  `skin:setAttachment` shares the attachment object; `attachment:copy()` makes a separate one. `skin:getAttachments()`
  returns `{slotName, placeholder, attachment}` records and `slot:getAttachmentEntries()`
  `{slotName, placeholder, skinName, attachment}` records. An Attachment exposes its type, name, colour and geometry
  (`x`, `y`, `rotation`, `scaleX`, `scaleY`, `width`, `height`, `vertices`, `triangles`, `bones`, `hullLength`,
  `worldVerticesLength`, and the path keys). Two Skin or Attachment objects are equal with `==` when they wrap the
  same native object. See the "Attachments and skins" page.
- **Added `skeleton:findSkin(name)`.** It returns the named skin of the skeleton data as a Skin object, or `nil`,
  without applying it. Thanks to [kan6868](https://github.com/kan6868).
- **Breaking: skin calls raise instead of warning and returning `false`.** A skin or slot that is not found, a wrong
  argument type, a skin, slot or attachment of other skeleton data, and an unknown or read-only property write on a
  Skin, Slot or Attachment (`SpineSkin: unknown property 'k'`, `SpineSlot: property 'name' is read-only`,
  `SpineAttachment: unknown property 'k' on a mesh attachment`) now raise a Lua error; nothing is printed to stderr.
  In 1.2.6 a slot property write was ignored and an unknown skin or attachment name printed a line and changed
  nothing. A slot argument is a slot name or a Slot object and a skin argument is a skin name or a Skin object; a
  string is always a name and a Lua number raises, so zero-based slot indexes no longer work. `skeleton:getSkin()`
  with an argument raises (use `findSkin`). Only the `find*` calls and a missing entry in `skin:getAttachment` return
  `nil`.
- **Breaking: `slot:getAttachments()` and `slot:getSkinAttachments()` return Attachment objects.** They returned
  attachment names in 1.2.6. `getSkinAttachments` takes a skin name or a Skin object, uses the applied skin (or
  else the default skin) without one, and raises `Skin not found: <name>` for an unknown skin name, where 1.2.6
  returned nothing.
- **Breaking: `skeleton:findSlot(name)` returns the Slot or `nil`** instead of a boolean; `getSlot` still raises when
  the slot does not exist.
- **Slots compare with `==`.** Two Slot objects are equal when they are the same slot of the same skeleton; in 1.2.6
  each read made a new object, so `==` was `false` even for the same slot.
- **Breaking: comparing a slot of a removed skeleton raises.** `==` with a Slot whose skeleton was removed raises
  `Slot belongs to a removed skeleton`.
- **Region attachment geometry setters take effect.** Writing `x`, `y`, `rotation`, `scaleX`, `scaleY`, `width` or
  `height` on a region attachment moves its vertices on the next draw.
- **Breaking: a slot with `slot.alpha = 0` draws no geometry.** Its attachment emits no vertices (a clipping
  attachment still clips); an object injected into that slot is still placed every drawn frame. An injected object is
  now also placed when the Spine slot colour's alpha or a mesh attachment's own alpha is 0; it used to be skipped.
- **A slot on an inactive skin bone is skipped, not an error.** After `skeleton:setSkin`, and after
  `skin:setAttachment` without a `sourceSkin`, a slot whose bone is a skin bone the applied skin does not enable raises
  nothing: its attachment is not updated and not drawn. Pass the attachment's skin as `sourceSkin`, or apply that
  skin, to draw it.
- **Added naming aliases, and keys that did nothing or raised now work.** Each of these keys reads and writes the
  same value as the key it pairs with, on both lines, with no warning, and neither name will be removed:
  - bone `scaleX`/`scaleY` and `xScale`/`yScale`; region attachment `scaleX`/`scaleY` and `xScale`/`yScale`;
  - `slot.a` and `slot.alpha`; `fill.color` (`{ r, g, b, a }`) and `fill.r/g/b/a`; `attachment.r/g/b/a` and
    `attachment.color`;
  - `entry.trackIndex` and `entry.index` (both read-only); `event.loop` and `event.looping` in animation events
    (every phase except `"event"`);
  - `skeleton:getIkConstraint(name)`/`getIkConstraintNames()` and `getIKConstraint`/`getIKConstraintNames`.

  `bone.scaleX = v`, `slot.a = v` and `fill.color = { … }` set nothing in 1.2.6 and now take effect. `xScale` and
  `yScale` on a non-region attachment raise an unknown-property error naming the key you wrote, and
  `entry.trackIndex = x` raises `SpineTrackEntry: property 'trackIndex' is read-only`.
- **`spine.loadAtlas()` warns about premultiplied-alpha atlases.** The plugin draws straight alpha only. When any
  page of the atlas declares `pma: true`, each `loadAtlas` call prints one line,
  `WARNING: plugin.spine: <path>: premultiplied-alpha atlas (pma: true) is not supported; export with straight alpha`,
  and the atlas still loads. Export the atlas with premultiplied alpha turned off to remove the warning.
- **The example projects run every demo scene.** The menus of `Corona/` (4.2) and `Corona43/` (4.3) list all 15
  scenes. "Attachment Object", "Attachment Properties" and "Attachment From Skin" now run on both lines and load
  straight-alpha atlases, so no example prints the premultiplied-alpha warning. Every example skeleton is Esoteric
  Software's Spine example art and its folder carries Esoteric Software's `license.txt`; the `hero` and `dragon`
  skeletons, whose licences allowed demonstration use only and forbade redistribution, are removed. The
  `spine-unity` art, the duplicate `mix-and-match.zip`, the Spine export scripts in `Corona43/spines/export/` and the
  `.CoronaLiveBuild` files are removed.

### plugin.spine42 (4.2 line)

- **Physics gravity points down on screen.** The plugin now uses Spine's native Y-down mode (`Bone::setYDown(true)`)
  instead of flipping the skeleton with `scaleY = -1`. Bone positions and `getBounds()` are unchanged (for
  `getSize()`, see "`getSize().offsetY` is `getBounds().yMin`" under "Both lines"), but physics constraint gravity,
  which pulled bones up on screen in 1.2.6, now pulls them down, as in the Spine editor. Content with non-zero
  gravity moves the other way than before.
- **Spine runtime refreshed to spine-cpp 4.2.120.** The vendored runtime moves to the 4.2.120 release, bringing
  upstream's 4.2 fixes (JSON and binary loading, clipping-aware bounds, memory leaks). The plugin's own runtime
  changes are kept.
- **A queued animation after a zero-length or short one no longer skips time.** An animation queued with
  `addAnimation` behind a zero-length or very short entry now starts at its delay instead of jumping ahead, and
  `entry.delay` is never negative.
- **With timeScale 0 (paused), a zero-mix `setAnimation` ends the old entry immediately.** Its `ended` and `disposed`
  events fire at the new animation's start instead of waiting for time to advance.
- **Breaking: sequence animations show the setup frame when mixed out** (matches the official 4.2.120 and 4.3
  runtimes). While a sequence (flipbook) animation mixes out, for example after `setEmptyAnimation` with a mix, its
  slot shows the setup frame and keeps it afterwards. It used to keep flipping frames during the mix-out and then stay
  on a mid-sequence frame.
- **Clipping masks match the Spine editor.** A clipping attachment on an inactive bone (a skin bone whose skin is not
  set) no longer clips the slots after it. A clip whose end slot holds a bounding box, point or path attachment now
  ends at that slot instead of clipping the rest of the draw order. On arm64 builds (iOS, Apple Silicon Mac, Android
  arm64) masks no longer drop whole pieces of a masked attachment or draw triangles outside the mask for single
  frames: the clipper and triangulator no longer use fused multiply-add, so their geometry is the editor's. A clipping
  attachment with fewer than 3 vertices is ignored, as in the editor, instead of hiding everything up to its end slot.
- **Physics no longer stops when the first physics constraint is inactive.** `draw` used to turn off every physics
  constraint of the skeleton when the first one was inactive (for example a constraint that belongs to a skin that is
  not set). Now only the inactive constraints are skipped.
- **Consecutive compatible attachments are drawn as one mesh.** The 4.2 renderer now batches consecutive attachments
  that share a texture and blend mode into one mesh, as the 4.3 line already did. A skeleton's `numChildren` and its
  child list change: 150 copies of the Spine raptor example go from 5,100 meshes to 450. Code that walks a
  skeleton's children sees fewer, larger meshes.
- **A custom event key in `.json` data without its own volume or balance reports `1` and `0`**, as the 4.2 runtime
  reads it; the 4.3 line reports the event's default volume and balance.

### Performance on Mac

Measured on Mac (Solar2D Simulator); devices may differ. Mac17,8 (Apple M5 Pro), macOS 27.0, Solar2D Simulator
2026.3731; `plugin.spine42` built Release (arm64 and x86_64) by Xcode from the 2.0.0 source, the 1.2.6 plugin from its
published Mac Simulator archive. Each plugin ran from its own plugins folder; 6 rounds interleaved, the first dropped,
so N = 5 per plugin; median (min–max).

Simulator, 150 copies of the Spine raptor example at scale 0.3, 30 warm-up and 300 measured frames
(`tests/sim/s6_perf.lua` driven by `tools/perf/sim-perf.sh`):

| per frame | `plugin.spine` 1.2.6 | `plugin.spine42` 2.0.0 |
|---|---|---|
| `updateState` and `draw` of all 150, ms | 14.59 (14.43–14.78) | 5.63 (5.60–5.65) |
| `enterFrame` interval, ms | 29.1 (27.9–29.4) | 16.0 (16.0–16.0) |
| Solar2D meshes | 5100 | 450 |
| Lua allocation with the collector stopped, KB | 7865.7 | 272.2 |

"ms" is the CPU time of the Lua calls, including the plugin's native work, not engine render or GPU time. The
Simulator process footprint at the end of the run is 303.4 MB (303.3–303.6) with 1.2.6 and 308.8 MB (308.1–309.7)
with 2.0.0. Batching itself costs CPU: in a headless build of the 4.2 renderer (`-O1`, `tools/perf/bench-ref.sh`, 18
example skeletons, 300 frames each), the batching renderer takes 0.00 to 1.92 µs more per frame than the same renderer
without batching (raptor 3.83 against 2.80 µs); the draw calls and meshes it saves are what the Simulator numbers show.

## 1.2.6 (Solar2D Free Plugin Directory release v21)

A bug-fix release of 1.2.5 (Directory release v20). The Lua API is unchanged, the Spine runtime is still 4.2, and the
minimum Solar2D build is unchanged. Every fix below is in a path where 1.2.5 crashed, corrupted memory or leaked.

**No migration needed.** Code that works on 1.2.5 works on 1.2.6 without changes. The load banner now prints `v1.2.6`.

### Fixed

Crashes in documented usage:

- **C1**: calling `obj:removeSelf()` or `display.remove(obj)` inside the animation listener (the usual "remove when
  completed" pattern) no longer crashes or corrupts memory.
- **C2**: keeping the atlas and skeleton data in local variables, as the quickstart does, no longer crashes after the
  garbage collector runs. The skeleton now keeps its data and atlas alive for as long as it needs them.
- **C10**: `obj:setAttachment(slot, name)` no longer crashes when `setSkin()` was never called. It uses the default skin,
  as Spine does.
- **C9**: `addAnimation`, `setEmptyAnimation` and `addEmptyAnimation` with track index 0 (or any index below 1) now raise
  `Invalid track index: N`, the error `setAnimation` already raises. Before, they crashed.
- **C11**: reading `.animation` from a held `obj.tracks[i]` entry that was replaced, cleared or finished now returns
  `nil` instead of crashing.

Leaks:

- **C3**: skeletons removed together with their parent group or composer scene are now freed. In 1.2.5 every such
  skeleton stayed in memory forever.
- **C5**: each `obj.fill` access no longer leaks a small object.
- **C8**: drawing a split skeleton no longer leaks 16 bytes per frame.
- **C16**: an atlas page texture loaded by several atlases is now released with the last of them. Before, it stayed in
  memory for the rest of the app's life once its atlas had been loaded twice.

Other crashes and corruption:

- **C4**: slots, bones, IK and physics constraints, tracks, track entries and fills that the app still holds after
  `obj:removeSelf()` (in a timer, a transition or a drag handler) no longer read freed memory. They keep returning the
  values the skeleton had when it was removed, as they do after a parent removal.
- **C6**: content whose first drawn piece is empty (an injected object in a slot whose region has alpha 0, an attachment
  fully outside a clipping attachment, some `split()` calls) no longer aborts the app.
- **C7**: `split()` now puts every mesh in the group it asked for. 1.2.5 drew some frames into the wrong group, and after
  `reassemble()` every `draw()` could raise errors. If the app removes the split group itself, the skeleton is drawn
  unsplit again instead of raising an error on every `draw()` (or aborting).
- **C12**: requiring the plugin for the first time from inside a coroutine no longer crashes once that coroutine is
  collected.
- **C13**: injection listeners may now call `obj:eject()`, `obj:inject()` or `obj:removeSelf()` during `draw()` without
  crashing.
- **C14a**: a physics "reset all constraints" key no longer crashes (upstream Spine fix 43b9f6cab).
- **C14b**: JSON content with a bone `inherit` timeline of two or more keys now loads instead of aborting or overflowing
  (upstream Spine fix a2859f68e).
- **C14c**: `getBounds()` and `getSize()` on binary (`.skel`) content with a weighted bounding box no longer read out of
  bounds or abort (upstream Spine fix 9207cd2a4).

### Differences you might notice

All of them are in code paths that crashed or leaked in 1.2.5.

- **Removed objects are released one frame later.** A skeleton removed with its parent group or composer scene is
  released on the next frame, and its native memory is returned at the next garbage collection.
- **Bounded retention.** While your app still references a removed object, its `event.target` or one of its wrappers,
  that skeleton's data, atlas and textures stay loaded. They are released once the last reference is dropped.
- **Split output.** `split()` frames that 1.2.5 drew into the wrong group are now drawn where `split()` asked (C7).
- **A hidden `finalize` listener.** Each spine object gets one extra `finalize` listener from the plugin. It appears in
  `obj._functionListeners`, and `obj:respondsToEvent("finalize")` returns `true`.
- **`getmetatable(event.target)`** stays non-nil after `removeSelf()`. In 1.2.5 it became `nil`.
- **Method values cached before a parent removal** (for example `local update = obj.updateState`) no longer drive the
  object's animation listener once the parent is removed.
- **Rest of an event batch.** If a listener removes the object while several animation events are being delivered, the
  remaining events of that batch are not delivered. 1.2.5 crashed there.
- **Memory profile.** Native memory is freed at garbage collection instead of immediately, so an app that creates and
  removes many skeletons quickly has a higher peak before the collector catches up.
- **Clearing all Runtime listeners.** The release of a parent-removed object runs from a one-shot `enterFrame` listener.
  If the app removes every Runtime listener in that frame, the release is skipped and the object stays in memory, as it
  did in 1.2.5.
- An error raised by an injection listener has the same message, but its traceback now starts at `draw()` (C13).

### Known issues kept from 1.2.5

- Calling a method on an object after removing it in the same frame (for example `obj:updateState(); obj:draw()` when
  the listener removed `obj`) raises `attempt to call method 'draw' (a nil value)`. Any removed Solar2D object behaves
  this way. Guard with `if obj.removeSelf then … end`.
- Calling the plugin's `removeSelf` on an object that Solar2D already finalized (stripped) still aborts the Simulator.

### Staying on 1.2.5

1.2.6 replaces 1.2.5 for every project that does not pin a version. To keep the 1.2.5 build, pin release v20 in
`build.settings`:

```lua
settings =
{
    plugins =
    {
        ["plugin.spine"] =
        {
            publisherId = "com.studycat",
            version = "v20",
        },
    },
}
```

This pin relies on the plugin's build key `2020.2600`, which later 1.2.x releases keep.
