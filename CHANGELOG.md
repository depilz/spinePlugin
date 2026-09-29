# Changelog

## Unreleased

### Both lines

- **Breaking: `ikConstraint.isActive` and `physics.isActive` are read-only.** Writing either now raises
  `IK constraint isActive is read-only; set mix = 0 to stop it` or
  `Physics constraint isActive is read-only; set mix = 0 to stop it`. Before, the write was accepted, but Spine
  overwrote it the next time it rebuilt the skeleton's update order (on `setSkin`, for example), so it did not
  reliably stop the constraint. Reading `isActive` is unchanged. To stop a constraint, set its `mix` to `0`, as the error says.
- **Physics steps without an animation track.** `updateState` now advances the skeleton's physics time even when no
  animation track exists, so a skeleton with physics and no animation simulates instead of standing still. Loops that
  call `updateState` and `draw` only while `skeleton.isActive` is `true` still skip such skeletons: `isActive` only
  tells whether the skeleton has a track.
- **Added `skeleton.physicsTimeScale`.** It scales the time step of the skeleton's Spine physics constraints: `1` by
  default, `0` pauses physics without a catch-up burst when it resumes. `timeScale` still does not affect physics.
  Writing a negative or non-finite value raises `physicsTimeScale must be a finite number >= 0`.
- **Removed skeletons are freed on the next frame, and objects you kept raise instead of reading freed memory.**
  `removeSelf()`, `display.remove()` and removing a parent group or a composer scene all take the same path: the
  skeleton stops updating, drawing and dispatching animation events at once, and a one-shot `Runtime` `enterFrame`
  listener frees its native memory on the next frame, so memory measured in the same frame still includes it. Bones,
  slots, constraints, fills, effects and track entries you kept keep working in the handler that removed the skeleton
  and in its `finalize` listeners; after that frame's finalize they raise `<Type> belongs to a removed skeleton`, and a
  skeleton method you stored raises `Skeleton belongs to a removed skeleton`. See the "Removing skeletons" page.
- **A removed skeleton only answers its event-dispatcher keys.** After `removeSelf()`, `addEventListener`,
  `removeEventListener`, `hasEventListener`, `dispatchEvent` and `respondsToEvent`, and the `getOrCreateTable`,
  `didRemoveListener` and `_setHasListener` helpers Solar2D's listener calls use, keep working until the end of that
  frame's finalize, inside `finalize` listeners too. Every other public key reads `nil`, including `removeSelf` and
  `numChildren`, so `if skeleton.removeSelf then` tells a removed skeleton from a live one. See the "Removing
  skeletons" page.
- **Breaking: `event.target` in animation events is the skeleton display object.** `event.target == skeleton` now
  holds; it used to be an internal userdata.
- **Added `entry.isValid`.** A track entry that has finished or was returned to the pool now raises
  `Track entry is no longer valid (finished or disposed); check entry.isValid` instead of reading pooled data or
  aliasing another entry.
- **Animation listener errors are reported.** An error in the listener passed to `spine.create()` used to vanish; it
  now reaches the console and the `unhandledError` event like any other Solar2D listener error, and the call that
  triggered it carries on.
- **Injection listeners may inject, eject or remove the skeleton during `draw`** without corrupting memory.
- **An IK target bone from another skeleton is rejected** with `target bone must belong to the same skeleton`.
- **`spine.loadAtlas()` raises `Failed to load texture: <path>` when a page texture cannot be loaded**, and keeps
  nothing in memory. `spine.create()` given an atlas instead of skeleton data raises an argument error instead of
  misreading it, and bad arguments to `spine.loadSkeletonData()` and `skeleton:inject()` no longer leak.
- **Leak fixes.** A texture shared by two atlases is released, reading `obj.fill` no longer leaks, and requiring the
  plugin or using a fill inside a coroutine no longer keeps the dead coroutine's state.
- **The split group belongs to you, and the skeleton cleans up after itself in it.** Removing a split skeleton now
  takes the skeleton's meshes out of the group returned by `split()` and leaves the group where you put it; they used
  to stay on screen. `removeSelf()` and `display.remove()` take them out at once; when the skeleton goes with its
  parent group or scene, they leave when its memory is freed on the next frame. If you remove the
  split group yourself, the skeleton draws unsplit from the next `draw` and a later `split()` returns a new group,
  instead of every `draw` raising; `reassemble()` after that no longer raises. `reassemble()` keeps an object injected
  into a split slot that is hidden at that moment, instead of destroying it with the group.
- **Injection listeners are called once per frame with the real visibility.** The listener passed to
  `skeleton:inject()` is now called once per `draw` with `isVisible = true` while its slot is drawn, once with
  `isVisible = false` on the frame its slot stops being drawn, and not at all while the slot stays hidden. It used to
  get an extra `isVisible = false` call before the `true` one on most frames, and in split mode on every frame. The
  event fields are unchanged.
- **A draw with an empty render command no longer aborts the Simulator, and `draw()` with extra arguments works.**
  A skeleton whose frame produced a render command with no vertices used to abort the Simulator on `draw`; calling
  `draw()` with extra arguments used to corrupt the Lua stack. Both now draw normally.
- **Meshes land in the right group and draw order after split, re-split, reassemble or injection.** A mesh reused from
  the skeleton group in the split group (or the other way round), or from another draw position, used to stay where it
  was, so pieces showed in the wrong group or on top of the wrong slots. It is now moved to its group and draw position.
- **A non-normal blend mode stays applied after a texture swap.** A slot drawn with `multiply`, `add` or `screen` used to
  fall back to normal blending when its mesh switched to another atlas page texture.
- **Mesh updates no longer create Lua garbage on every draw.** Updating a skeleton's meshes reuses one parameter table
  and its vertex buffers instead of allocating new ones per mesh per draw: for 150 copies of the Spine raptor example,
  Lua allocation drops from about 7.9 MB to about 0.27 MB per frame.
- **Breaking: custom animation events have `name = "spine"` and `phase = "event"`.** Every animation event now has
  `event.name == "spine"`. A custom event keyed in Spine has `event.phase == "event"` and its name in `event.event`,
  plus `int`, `float`, `string`, `time`, `animation`, `trackIndex` and `target`, and `audioPath`, `volume` and
  `balance` when it has audio. It used to arrive with its name in `event.name` and no `phase`, so a listener that
  tells custom events apart with `event.name ~= "spine"` must check `event.phase == "event"` instead. A custom event
  named `"spine"` no longer looks like a lifecycle event. Lifecycle events are unchanged.
- **Breaking: custom events carry the values of the key that fired.** `event.int`, `event.float`, `event.string`,
  `event.volume` and `event.balance` are the values set on that key in the animation; they used to be the event's
  default values from the Spine editor for every key. The new `event.time` is the key's time in milliseconds.
- **Breaking: `skeleton.isActive` is `true` only while a track has a current entry.** It becomes `false` after
  `clearTrack` on the last track that had an entry, and once an empty animation that mixes a track out has ended on
  every track. It used to stay `true` until `clearTracks`, as "Physics steps without an animation track" above still
  describes it. Loops that call `updateState` and `draw` only while
  `isActive` is `true` stop updating such a skeleton earlier than before.
- **Breaking: physics steps in `updateState`, and `draw` only poses.** `updateState` now steps the physics
  constraints and poses the skeleton, so bone and slot world values, `getBounds()` and `getSize()` are current after
  every `updateState`, and right after `spine.create()`. `draw` poses without stepping physics, so bone changes made
  from Lua between `updateState` and `draw` are drawn, and physics reacts at the next `updateState`. With one
  `updateState` and one `draw` per frame nothing changes. Code that calls `draw` without `updateState`, `updateState`
  several times per `draw`, or `updateState` without `draw` (for example for off-screen skeletons) now moves physics
  once per `updateState` instead of once per `draw`.
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
- **`addAnimationAt` no longer waits for the previous entry to complete when its time has already passed.** On a
  track that is playing, a time at or before the start of the last queued entry now starts the new entry on the
  update right after that entry starts. It used to start when that entry completed. Times after it are unchanged.
- **`setEmptyAnimation` and `addEmptyAnimation` return their track entry.** They used to return nothing.
  `setEmptyAnimations` still returns nothing.
- **Track entries compare with `==`.** Two track-entry objects are equal when they stand for the same entry, for
  example `skeleton:getTrackEntry(1) == skeleton.tracks[1]`. Comparing never raises.
- **Added `spine.version` and `spine.runtimeVersion`.** `spine.version` is the plugin version (`"2.0.0"` for
  `plugin.spine42`, `"3.0.0"` for `plugin.spine43`) and `spine.runtimeVersion` the Spine runtime line (`"4.2"` or
  `"4.3"`).
- **Load errors say why.** `spine.loadSkeletonData()` raises
  `Failed to load skeleton data: <path>: <reason>` with the Spine runtime's reason, for example a version mismatch,
  and `spine.loadAtlas()` adds the error `graphics.newTexture` raised to `Failed to load texture: <path>`. The message
  prefixes are unchanged.

### plugin.spine42 (4.2 line)

- **Physics gravity points down on screen.** The plugin now uses Spine's native Y-down mode (`Bone::setYDown(true)`)
  instead of flipping the skeleton with `scaleY = -1`. Bone positions, `getBounds()` and `getSize()` are unchanged, but
  physics constraint gravity, which pulled bones up on screen in 1.5.0, now pulls them down, as in the Spine editor.
  Content with non-zero gravity moves the other way than before.
- **Spine runtime refreshed to spine-cpp 4.2.120.** The vendored runtime moves from an October 2024 4.2 snapshot to the
  4.2.120 release, bringing upstream's 4.2 fixes (JSON and binary loading, clipping-aware bounds, memory leaks). The
  plugin's own runtime changes are kept.
- **A queued animation after a zero-length or short one no longer skips time.** An animation queued with
  `addAnimation` behind a zero-length or very short entry now starts at its delay instead of jumping ahead, and
  `entry.delay` is never negative.
- **With timeScale 0 (paused), a zero-mix `setAnimation` ends the old entry immediately.** Its `ended` and `disposed`
  events fire at the new animation's start instead of waiting for time to advance.
- **Sequence animations show the setup frame when mixed out** (matches the official 4.2.120 and 4.3 runtimes). While
  a sequence (flipbook) animation mixes out, for example after `setEmptyAnimation` with a mix, its slot shows the setup
  frame and keeps it afterwards. It used to keep flipping frames during the mix-out and then stay on a mid-sequence
  frame.
- **Clipping masks match the Spine editor.** A clipping attachment on an inactive bone (a skin bone whose skin is not
  set) no longer clips the slots after it. A clip whose end slot holds a bounding box, point or path attachment now
  ends at that slot instead of clipping the rest of the draw order. On arm64 builds (iOS, Apple Silicon Mac, Android
  arm64) masks no longer drop whole pieces of a masked attachment or draw triangles outside the mask for single
  frames: the clipper and triangulator no longer use fused multiply-add, so their geometry is the editor's. A clipping
  attachment with fewer than 3 vertices is ignored, as in the editor, instead of hiding everything up to its end slot.
- **Physics no longer stops when the first physics constraint is inactive.** `draw` used to turn off every physics
  constraint of the skeleton when the first one was inactive (for example a constraint that belongs to a skin that is
  not set). Now only the inactive constraints are skipped.
- **Split rendering no longer leaks on every draw.** The split renderer allocated a command pair per draw and never
  freed it; it now returns the pair by value, as the 4.3 line already did.
- **Consecutive compatible attachments are drawn as one mesh.** The 4.2 renderer now batches consecutive attachments
  that share a texture and blend mode into one mesh, as the 4.3 line already did. A skeleton's `numChildren` and its
  child list change: 150 copies of the Spine raptor example go from 5,157 meshes to about 450. Code that walks a
  skeleton's children sees fewer, larger meshes.
- **`getSize().offsetY` changes sign.** "Physics gravity points down on screen" above says `getSize()` is unchanged;
  that still holds for `width`, `height` and `offsetX`, but `offsetY` is now `yMin` (see "Both lines").
- **A custom event key in `.json` data without its own volume or balance reports `1` and `0`**, as the 4.2 runtime
  reads it; the 4.3 line reports the event's default volume and balance.

### plugin.spine43 (4.3 line)

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
- **`ikConstraint.isActive` and `physics.isActive` read `false` for an inactive constraint.** Both always read `true`
  on the 4.3 line, because of a spine-cpp 4.3 runtime bug (also upstream): `Skeleton::updateCache` set a different
  active flag than the one `isActive()` reads. The vendored runtime is patched so every constraint type (IK, transform,
  path, physics, slider) has a single active flag. Behaviour change: animation timelines no longer change a constraint
  that is inactive (skin-required and not in the current skin), as on the 4.2 line and in the Spine editor. Before,
  they still keyed its mix and other pose values, and a physics timeline could reset it.

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
