# Changelog

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
