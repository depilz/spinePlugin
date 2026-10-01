=========
Migration
=========

This page moves a project from the public ``plugin.spine`` 1.2.6 to ``plugin.spine42`` 2.0.0 (the Spine 4.2 line),
and then, if you want it, from ``plugin.spine42`` to ``plugin.spine43`` 3.0.0 (the Spine 4.3 line). Each item says
what changed, shows the code before and after, gives the error the plugin raises when old code hits the change, says
in one line what to change, and links its entry in the `CHANGELOG`_. The "before" samples are 1.2.6 code: ``obj``
is the skeleton there, as in the 1.2 documentation.

Keys that gained a second name are listed under `New names`_; they change nothing in code that works today.

.. _CHANGELOG: https://github.com/depilz/spinePlugin/blob/main/CHANGELOG.md
.. _both lines: https://github.com/depilz/spinePlugin/blob/main/CHANGELOG.md#both-lines
.. _4.2 line: https://github.com/depilz/spinePlugin/blob/main/CHANGELOG.md#pluginspine42-42-line

From plugin.spine 1.2.6 to plugin.spine42
=========================================

``plugin.spine42`` runs the same Spine line as 1.2.6 (4.2), so skeletons exported for 1.2.6 load without a new
export.

Plugin name
-----------

The plugin is published once per Spine line, and the 4.2 line is ``plugin.spine42``.

- **Before:** ``["plugin.spine"]`` in ``build.settings`` and ``require("plugin.spine")``.
- **After:**

  .. code-block:: lua

      settings =
      {
          plugins =
          {
              ["plugin.spine42"] =
              {
                  publisherId = "com.studycat",
                  supportedPlatforms =
                  {
                      android        = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-android.tgz" },
                      iphone         = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-iphone.tgz" },
                      ["iphone-sim"] = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-iphone-sim.tgz" },
                      ["mac-sim"]    = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-mac-sim.tgz" },
                      ["win32-sim"]  = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-win32-sim.tgz" },
                      ["linux-sim"]  = { url = "https://github.com/depilz/spinePlugin/releases/download/spine42-2.0.0/plugin.spine42-2.0.0-linux-sim.tgz" },
                  },
              },
          },
      }

  .. code-block:: lua

      local spine = require("plugin.spine42")

- **What to change:** rename the plugin in ``build.settings`` and in every ``require``.
- **CHANGELOG:** `both lines`_, "Breaking: the plugin is published once per Spine line".

Animation events
----------------

Custom events have ``name = "spine"`` and ``phase = "event"``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Every animation event is now named ``"spine"``. A custom event keyed in Spine has ``phase = "event"`` and its own
name in ``event.event``.

- **Before:**

  .. fragment: 1.2.6 listener body; event is the listener's argument
  .. code-block:: lua

      if event.name == "footstep" then
          print("step")
      end

- **After:**

  .. code-block:: lua

      skeleton:setListener(function(event)
          if event.phase == "event" and event.event == "footstep" then
              print("step")
          end
      end)
      skeleton:setAnimation(1, "walk", true)

- **What to change:** test ``event.phase == "event"`` and read the custom event's name from ``event.event``.
- **CHANGELOG:** `both lines`_, "Breaking: custom animation events have name = "spine" and phase = "event", and carry the
  values of the key that fired".

Custom events carry the values of the key that fired
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``event.int``, ``event.float``, ``event.string``, ``event.volume`` and ``event.balance`` are the values set on the
key in the animation. In 1.2.6 they were the event's default values from the Spine editor, whatever the key said.
The new ``event.time`` is the key's time in milliseconds.

- **Before:**

  .. fragment: 1.2.6 listener body; event is the listener's argument
  .. code-block:: lua

      local damage = event.int -- the event's default value in 1.2.6

- **After:**

  .. code-block:: lua

      skeleton:setListener(function(event)
          if event.phase == "event" then
              print(event.event, event.int, event.float, event.string, event.time)
          end
      end)
      skeleton:setAnimation(1, "walk", true)

- **What to change:** nothing, unless the code expected every key to report the defaults.
- **CHANGELOG:** `both lines`_, "Breaking: custom animation events have name = "spine" and phase = "event", and carry the
  values of the key that fired".

``event.target`` is the skeleton
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``event.target == skeleton`` holds in every animation event. In 1.2.6 it was an internal userdata.

- **Before:**

  .. fragment: 1.2.6 listener body; event is the listener's argument
  .. code-block:: lua

      print(type(event.target)) -- "userdata" in 1.2.6

- **After:**

  .. code-block:: lua

      skeleton:setListener(function(event)
          if event.target == skeleton then
              print(event.phase, event.animation)
          end
      end)
      skeleton:setAnimation(1, "walk", true)

- **What to change:** drop any lookup that mapped the old userdata back to the skeleton; use ``event.target``.
- **CHANGELOG:** `both lines`_, "Breaking: event.target in animation events is the skeleton display object".

Listener errors are reported
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An error in the listener passed to ``spine.create()`` used to vanish. It now reaches the console and the
``unhandledError`` event like any other Solar2D listener error, and the call that triggered it carries on.

- **Before:**

  .. fragment: 1.2.6 listener body with a typo; event is the listener's argument
  .. code-block:: lua

      print(event.animaton.name) -- the error was dropped in 1.2.6

- **After:** the same line reports ``attempt to index field 'animaton' (a nil value)``.
- **What to change:** fix the errors that now show up.
- **CHANGELOG:** `both lines`_, "Animation listener errors are reported".

Updating and drawing
--------------------

``skeleton.tracks`` is a plain table
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Each read of ``skeleton.tracks`` builds a new table: ``tracks[i]`` is the current entry of track ``i``, or
``false`` for an empty track, up to the highest track used. ``ipairs`` and ``#`` work on it. In 1.2.6 it was a
proxy object: ``ipairs`` raised on it and an empty track read ``nil``.

- **Before:**

  .. fragment: 1.2.6 code; obj is the app's skeleton
  .. code-block:: lua

      local tracks = obj.tracks
      for i = 1, #tracks do
          if tracks[i] ~= nil then
              print(tracks[i].animation)
          end
      end

- **After:**

  .. code-block:: lua

      skeleton:setAnimation(2, "walk", true)
      for i, entry in ipairs(skeleton.tracks) do
          if entry then
              print(i, entry.animation)
          end
      end

- **What to change:** test ``if tracks[i] then`` rather than ``~= nil``.
- **CHANGELOG:** `both lines`_, "Breaking: skeleton.tracks is a plain table".

``skeleton.isActive`` is ``true`` only while a track plays
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``isActive`` is ``true`` only while a track has a current entry. It becomes ``false`` after ``clearTrack`` on the
last track that had one, and once an empty animation that mixes a track out has ended. In 1.2.6 it stayed ``true``
until ``clearTracks``. ``updateState`` also advances physics now when no track exists; in 1.2.6 it did nothing then.

- **Before:**

  .. fragment: 1.2.6 code; obj is the app's skeleton
  .. code-block:: lua

      if obj.isActive then
          obj:updateState(dt)
          obj:draw()
      end

- **After:**

  .. code-block:: lua

      Runtime:addEventListener("enterFrame", function()
          skeleton:updateState(1000 / 60)
          skeleton:draw()
      end)

- **What to change:** update and draw every skeleton that is on screen, or gate the loop on your own flag; a
  skeleton with physics and no animation needs ``updateState`` to simulate.
- **CHANGELOG:** `both lines`_, "Breaking: skeleton.isActive is true only while a track has a current entry" and
  "Breaking: physics steps in updateState, and draw only poses".

Physics steps in ``updateState``, and ``draw`` only poses
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``updateState`` steps physics and poses the skeleton, so bone and slot world values, ``getBounds()`` and
``getSize()`` are current after it. ``draw`` poses without stepping physics. In 1.2.6 ``draw`` stepped physics
whenever the first physics constraint was active. With one ``updateState`` and one ``draw`` per frame nothing
changes.

- **Before:**

  .. fragment: 1.2.6 code; obj is the app's skeleton
  .. code-block:: lua

      obj:draw() -- stepped physics in 1.2.6, without an updateState

- **After:**

  .. code-block:: lua

      skeleton:updateState(1000 / 60)
      skeleton:draw()

- **What to change:** call ``updateState`` once before each ``draw``; physics moves once per ``updateState``.
- **CHANGELOG:** `both lines`_, "Breaking: physics steps in updateState, and draw only poses".

Physics gravity points down on screen
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The 4.2 line runs Spine in its Y-down mode instead of flipping the skeleton with ``scaleY = -1`` as 1.2.6 did.
Bone positions and bounds are unchanged, but physics gravity, which pulled bones up on screen in 1.2.6, now pulls
them down, as in the Spine editor.

- **Before:** a positive gravity lifted the bones on screen.
- **After:** a positive gravity pulls the bones down on screen.
- **What to change:** if you inverted gravity in the Spine editor to make it look right in 1.2.6, set it back.
- **CHANGELOG:** `4.2 line`_, "Physics gravity points down on screen".

``getSize().offsetY`` is ``getBounds().yMin``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``(offsetX, offsetY)`` is the top-left corner of the bounds in the skeleton's y-down coordinates. In 1.2.6
``offsetY`` was ``-yMin``. ``width``, ``height`` and ``offsetX`` are unchanged.

- **Before:**

  .. fragment: 1.2.6 code; obj is the app's skeleton
  .. code-block:: lua

      local top = -obj:getSize().offsetY

- **After:**

  .. code-block:: lua

      local top = skeleton:getSize().offsetY
      print(top == skeleton:getBounds().yMin)

- **What to change:** flip the sign where you read ``offsetY``.
- **CHANGELOG:** `both lines`_, "Breaking: getSize().offsetY is getBounds().yMin".

Consecutive attachments are drawn as one mesh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The 4.2 renderer batches consecutive attachments that share a texture and blend mode into one mesh, so a
skeleton has fewer, larger children than in 1.2.6.

- **Before:**

  .. fragment: 1.2.6 code; obj is the app's skeleton and slotIndex a slot's draw position
  .. code-block:: lua

      local mesh = obj[slotIndex] -- one child per attachment in 1.2.6

- **After:** a child mesh can hold several attachments; ``numChildren`` is smaller.
- **What to change:** do not address a skeleton's children by slot; put your own display objects in a slot with
  :doc:`api_reference/skeleton/inject`.
- **CHANGELOG:** `4.2 line`_, "Consecutive compatible attachments are drawn as one mesh".

Sequence animations show the setup frame when mixed out
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

While a sequence (flipbook) animation mixes out, its slot shows the setup frame and keeps it afterwards, as the
official Spine runtimes do.

- **Before:** the slot kept flipping frames during the mix-out, then stayed on a mid-sequence frame.
- **After:** the slot shows the setup frame.
- **What to change:** key the frame you want in the animation that follows, if the setup frame is not it.
- **CHANGELOG:** `4.2 line`_, "Breaking: sequence animations show the setup frame when mixed out".

Track entries
-------------

Writing an unknown or read-only track-entry key raises
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **Before:**

  .. fragment: 1.2.6 code; entry is a track entry the app holds
  .. code-block:: lua

      entry.animationTime = 0 -- ignored in 1.2.6

- **After:**

  .. code-block:: lua

      local entry = skeleton:setAnimation(1, "walk", true)
      entry.trackTime = 0

- **Error:** ``SpineTrackEntry: property 'animationTime' is read-only`` for ``index``, ``animation``,
  ``animationTime``, ``isComplete``, ``isValid``, ``trackComplete``, ``next``, ``mixingFrom`` and ``mixingTo``;
  ``SpineTrackEntry: unknown property '<key>'`` for any other key the entry does not have.
- **What to change:** write only the writable keys the :doc:`api_reference/skeleton/trackEntry/index` pages list.
- **CHANGELOG:** `both lines`_, "Breaking: writing an unknown or read-only track-entry key raises".

A finished track entry raises
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A track entry that finished or went back to Spine's pool raises when you read it. In 1.2.6 ``entry.animation``
read ``nil`` then.

- **Before:**

  .. fragment: 1.2.6 code; entry is a track entry the app holds
  .. code-block:: lua

      if entry.animation == nil then
          print("finished")
      end

- **After:**

  .. code-block:: lua

      local entry = skeleton:setAnimation(1, "walk", false)
      if entry.isValid then
          print(entry.animation)
      end

- **Error:** ``Track entry is no longer valid (finished or disposed); check entry.isValid``.
- **What to change:** check ``entry.isValid`` before reading an entry you kept.
- **CHANGELOG:** `both lines`_, "Breaking: a finished track entry raises; added entry.isValid".

Bones and constraints
---------------------

Writing ``bone.worldX`` or ``bone.worldY`` raises
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **Before:**

  .. fragment: 1.2.6 code; bone is a bone the app holds
  .. code-block:: lua

      bone.worldX = 100 -- ignored in 1.2.6

- **After:**

  .. code-block:: lua

      local bone = skeleton.bones[2]
      bone:setWorldPosition(100, -50)
      skeleton:updateState(0)

- **Error:** ``worldX is read-only; use bone:setWorldPosition(x, y)`` (or ``worldY``).
- **What to change:** use :doc:`api_reference/skeleton/bone/setWorldPosition` or
  :doc:`api_reference/skeleton/bone/translateWorld`.
- **CHANGELOG:** `both lines`_, "Breaking: writing bone.worldX or bone.worldY raises".

``ikConstraint.isActive`` and ``physics.isActive`` are read-only
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In 1.2.6 the write was accepted, but Spine overwrote it the next time it rebuilt the skeleton's update order, so it
did not reliably stop the constraint.

- **Before:**

  .. fragment: 1.2.6 code; ik is an IK constraint the app holds
  .. code-block:: lua

      ik.isActive = false

- **After:**

  .. code-block:: lua

      skeleton:getIkConstraint("front-leg-ik").mix = 0

- **Error:** ``IK constraint isActive is read-only; set mix = 0 to stop it`` and
  ``Physics constraint isActive is read-only; set mix = 0 to stop it``.
- **What to change:** set the constraint's ``mix`` to ``0`` to stop it.
- **CHANGELOG:** `both lines`_, "Breaking: ikConstraint.isActive and physics.isActive are read-only".

Slots and skins
---------------

``skeleton:findSlot(name)`` returns the slot
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It returns the Slot or ``nil``. In 1.2.6 it returned ``true`` or ``false``.

- **Before:**

  .. fragment: 1.2.6 code; obj is the app's skeleton
  .. code-block:: lua

      if obj:findSlot("head") == true then
          print("has a head")
      end

- **After:**

  .. code-block:: lua

      local head = skeleton:findSlot("head")
      if head then
          print(head.name)
      end

- **What to change:** test the result for truth, not ``== true``.
- **CHANGELOG:** `both lines`_, "Breaking: skeleton:findSlot(name) returns the Slot or nil".

``slot:getAttachments()`` and ``slot:getSkinAttachments()`` return attachments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Both return Attachment objects instead of attachment names. ``getSkinAttachments`` takes a skin name or a Skin
object, uses the applied skin (or else the default skin) without one, and raises for a skin that does not exist;
in 1.2.6 it returned nothing then.

- **Before:**

  .. fragment: 1.2.6 code; slot is a slot the app holds
  .. code-block:: lua

      for _, name in ipairs(slot:getAttachments()) do
          print(name)
      end

- **After:**

  .. code-block:: lua

      local slot = skeleton:getSlot("head")
      for _, attachment in ipairs(slot:getAttachments()) do
          print(attachment.name)
      end

- **Error:** ``Skin not found: <name>`` from ``getSkinAttachments`` with an unknown skin name.
- **What to change:** read ``attachment.name`` where you used the name.
- **CHANGELOG:** `both lines`_, "Breaking: slot:getAttachments() and slot:getSkinAttachments() return Attachment
  objects".

Slot property writes and slot arguments raise
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Writing an unknown or read-only slot key raises; in 1.2.6 it was ignored. A slot argument is a slot name or a Slot
object: a string is always a name and a Lua number raises.

- **Before:**

  .. fragment: 1.2.6 code; slot is a slot the app holds
  .. code-block:: lua

      slot.visible = false -- ignored in 1.2.6

- **After:**

  .. code-block:: lua

      local slot = skeleton:getSlot("head")
      slot.alpha = 0

- **Error:** ``SpineSlot: unknown property 'visible'``; ``SpineSlot: property 'name' is read-only``;
  ``SpineSlot: property 'darkColor' is read-only; the skeleton data and its animations set it``.
- **What to change:** write only the keys the :doc:`api_reference/skeleton/slot/index` pages list, and pass slot
  names, not indexes.
- **CHANGELOG:** `both lines`_, "Breaking: skin calls raise instead of warning and returning false" and
  "Breaking: added slot.darkColor, read-only".

Comparing slots
~~~~~~~~~~~~~~~

Two Slot objects are equal with ``==`` when they are the same slot of the same skeleton. In 1.2.6 each read made a
new object, so ``==`` was ``false`` even for the same slot. Comparing a slot of a removed skeleton raises.

- **Before:**

  .. fragment: 1.2.6 code; obj is the app's skeleton
  .. code-block:: lua

      print(obj:getSlot("head") == obj:getSlot("head")) -- false in 1.2.6

- **After:**

  .. code-block:: lua

      print(skeleton:getSlot("head") == skeleton:getSlot("head"))

- **Error:** ``Slot belongs to a removed skeleton``.
- **What to change:** compare slots with ``==`` directly, and not after their skeleton was removed.
- **CHANGELOG:** `both lines`_, "Slots compare with ==" and "Breaking: comparing a slot of a removed skeleton
  raises".

A slot with ``alpha = 0`` draws no geometry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Its attachment emits no vertices (a clipping attachment still clips). An object injected into the slot is still
placed on every drawn frame.

- **Before:** the slot's mesh was drawn fully transparent.
- **After:**

  .. code-block:: lua

      skeleton:getSlot("head").alpha = 0

  draws nothing for the head slot.
- **What to change:** nothing, unless the code relied on the transparent mesh, for example as a child of the
  skeleton.
- **CHANGELOG:** `both lines`_, "Breaking: a slot with slot.alpha = 0 draws no geometry".

Injection and drawing
---------------------

Injection listeners are called once per frame
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The listener passed to ``skeleton:inject()`` is called once per ``draw`` with ``isVisible = true`` while its slot is
drawn, once with ``isVisible = false`` on the frame the slot stops being drawn, and not at all while the slot stays
hidden. It used to get an extra ``isVisible = false`` call before the ``true`` one on most frames.

- **Before:**

  .. fragment: 1.2.6 listener body; event is the injection listener's argument
  .. code-block:: lua

      if not event.isVisible then
          hiddenCalls = hiddenCalls + 1 -- counted the extra calls in 1.2.6
      end

- **After:** one call per drawn frame; the ``isVisible = false`` call means the slot was hidden.
- **What to change:** nothing, unless the code counted calls or reacted to the extra ``false`` call.
- **CHANGELOG:** `both lines`_, "Breaking: injection listeners are called once per frame with the real visibility".

Tint black renders dark colours
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Slots with a dark colour (Spine's "Tint black") other than black are drawn with it, as in the Spine editor. The
plugin defines the Solar2D effect ``filter.custom.plugin_spine_tintBlack`` for this.

- **Before:** the plugin ignored dark colours.
- **After:** art with dark colours renders as in the Spine editor; skeletons without dark colours render as before.
- **What to change:** do not define an effect named ``filter.custom.plugin_spine_tintBlack`` in your app.
- **CHANGELOG:** `both lines`_, "Tint black: art with dark colours now renders as in the Spine editor".

Premultiplied-alpha atlases print a warning
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The plugin draws straight alpha only. ``spine.loadAtlas()`` prints one line for an atlas whose pages declare
``pma: true``, and still loads it.

- **Before:** no message.
- **After:** ``WARNING: plugin.spine: <path>: premultiplied-alpha atlas (pma: true) is not supported; export with
  straight alpha``.
- **What to change:** export the atlas with premultiplied alpha turned off.
- **CHANGELOG:** `both lines`_, "spine.loadAtlas() warns about premultiplied-alpha atlases".

Removed skeletons
-----------------

Objects kept after removal raise
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A removed skeleton is freed on the next frame. Bones, slots, constraints, fills, effects and track entries you kept
keep working in the handler that removed it and in its ``finalize`` listeners; after that frame they raise. In
1.2.6 they kept returning the values the skeleton had when it was removed. See :doc:`lifecycle`.

- **Before:**

  .. fragment: 1.2.6 code; bone is a bone the app kept after obj:removeSelf()
  .. code-block:: lua

      print(bone.x) -- the last value in 1.2.6

- **After:**

  .. code-block:: lua

      local bone = skeleton.bones[2]
      skeleton:removeSelf()
      timer.performWithDelay(100, function()
          if skeleton.removeSelf then
              print(bone.x)
          end
      end)

- **Error:** ``Bone belongs to a removed skeleton`` (``Slot``, ``IK constraint``, ``Physics constraint``,
  ``Fill``, ``Effect``, ``Track entry`` for the other types), and ``Skeleton belongs to a removed skeleton`` from a
  skeleton method you stored.
- **What to change:** drop the objects you keep when you remove the skeleton, or test ``skeleton.removeSelf``
  first.
- **CHANGELOG:** `both lines`_, "Breaking: removed skeletons are freed on the next frame, and objects you kept raise
  instead of reading freed memory".

New names
---------

These keys now have a second name that reads and writes the same value, on both lines, with no warning. Both names
stay; the :doc:`naming` page explains which one each page documents. A 1.2.6 name that is not in this table did
not change.

.. list-table::
   :header-rows: 1
   :widths: 30 34 36

   * - Before (1.2.6)
     - After (also accepted)
     - Note
   * - ``bone.xScale``, ``bone.yScale``
     - ``bone.scaleX``, ``bone.scaleY``
     - ``bone.scaleX = v`` set nothing in 1.2.6; it now scales the bone.
   * - ``slot.alpha``
     - ``slot.a``
     -
   * - ``skeleton.fill.r``, ``g``, ``b``, ``a``
     - ``skeleton.fill.color`` (``{ r, g, b, a }``)
     - ``fill.color = { … }`` set nothing in 1.2.6; it now sets the fill colour.
   * - ``entry.index``
     - ``entry.trackIndex``
     - Both read-only.
   * - ``event.looping``
     - ``event.loop``
     - In animation events of every phase except ``"event"``.
   * - ``skeleton:getIKConstraint()``, ``getIKConstraintNames()``
     - ``skeleton:getIkConstraint()``, ``getIkConstraintNames()``
     -

- **Error:** none; old code keeps working.
- **What to change:** nothing.
- **CHANGELOG:** `both lines`_, "Added naming aliases, and keys that did nothing or raised now work".

From plugin.spine42 to plugin.spine43
=====================================

The two lines share their Lua API, except where Spine 4.3 itself differs: skeletons need a new export,
``trackEntry.holdPrevious`` is gone, the 4.3 line adds keys for what is new in Spine 4.3, and a few values that come
from the runtime change.

.. _4.3 line: https://github.com/depilz/spinePlugin/blob/main/CHANGELOG.md#pluginspine43-300

Plugin name
-----------

- **Before:** ``["plugin.spine42"]`` in ``build.settings`` and ``require("plugin.spine42")``.
- **After:**

  .. code-block:: lua

      local spine = require("plugin.spine43")

  with ``["plugin.spine43"]`` in ``build.settings``.
- **What to change:** rename the plugin in ``build.settings`` and in every ``require``.
- **CHANGELOG:** `both lines`_, "Breaking: the plugin is published once per Spine line".

Re-export your skeletons with Spine 4.3
---------------------------------------

The 4.3 line reads only skeleton data exported by Spine 4.3. Export with Spine **4.3.75-beta or older**: the
line's Spine runtime is spine-cpp as of upstream ``spine-ts-4.3.13``, and the examples it is tested with were exported
by 4.3.75-beta. Data from a newer 4.3 editor is not tested.

- **Before:** ``.json`` and ``.skel`` files exported with Spine 4.2.
- **After:** the same skeletons exported again with the Spine 4.3.75-beta editor or older, with their atlases.
- **Error:** ``Failed to load skeleton data: <path>: Skeleton version 4.2.<patch> does not match runtime version
  4.3``.
- **What to change:** open each project in Spine 4.3.75-beta or older and export the skeleton and its atlas again.
- **CHANGELOG:** `4.3 line`_, "The Spine runtime is frozen at spine-ts-4.3.13; export with Spine 4.3.75-beta or older".

``trackEntry.holdPrevious`` is removed
--------------------------------------

Spine 4.3 has no hold-previous flag on a track entry, because its runtime always holds: while an entry mixes in,
the previous entry on the track keeps covering every property the new animation also keys, including one a lower
track keys, so the lower track does not show through the mix. That is what ``holdPrevious = true`` did on the 4.2
line. Properties the new animation does not key fade out over the mix, as do the ones an ``additive`` entry adds to.
On the 4.3 line reading or writing ``holdPrevious`` raises; the 4.2 line keeps it.

The error names ``additive`` and ``mixInterpolation``, the new track-entry keys, but neither takes the place of
``holdPrevious``. An ``additive`` entry adds its animation to the pose of the tracks below it instead of covering
them, so they show through more, not less. ``mixInterpolation`` changes only how the mix progresses over its
``mixDuration``. Both are on the track entry page of the 4.3 documentation.

- **Before:**

  .. fragment: 4.2 code; entry is a track entry the app holds
  .. code-block:: lua

      entry.holdPrevious = true

- **After:** the entries alone, with no flag, for example:

  .. code-block:: lua

      spineboy:setAnimation(1, "run", true)
      spineboy:setAnimation(2, "aim", false)
      spineboy:addAnimation(2, "shoot", false, 500)

- **Error:** ``SpineTrackEntry: property 'holdPrevious' was removed in Spine 4.3; use additive or mixInterpolation``.
- **What to change:** drop ``holdPrevious``; nothing replaces it. Don't set ``additive`` in its place: it changes
  the pose, not the mix.
- **CHANGELOG:** `4.3 line`_, "Breaking: trackEntry.holdPrevious is removed".

New keys
--------

The 4.3 line adds keys for what is new in Spine 4.3. Each has its page in the API reference of the 4.3
documentation; the 4.2 line does not have them.

- ``trackEntry.additive`` (``true``/``false``) and ``trackEntry.mixInterpolation`` (``"linear"``, ``"smooth"``,
  ``"slowFast"``, ``"fastSlow"`` or ``"circle"``).
- ``slot.appliedAttachment``, read-only: the attachment the renderer draws, which a slider constraint can make differ
  from ``slot.attachment``.
- ``skeleton.sliders``, read-only: the skeleton's slider constraints by name, with ``time`` and ``mix`` to read and
  write and ``duration``, ``name``, ``animation``, ``loop`` and ``boneDriven`` to read.
- ``attachment.region``, read-only: the atlas region a region or mesh attachment shows;
  ``attachment:copy{ region = … }``: a copy that shows another region of the skeleton's atlas;
  ``skeleton:createAttachment{ region = …, name = … }``: a new region attachment.

- **Error:** none; code written for the 4.2 line does not use them.
- **What to change:** nothing.
- **CHANGELOG:** `4.3 line`_, the "Added" entries.

``attachment.hullLength`` counts numbers
----------------------------------------

On the 4.3 line ``hullLength`` counts numbers (x and y of each hull vertex); on the 4.2 line it counts vertices.
The same mesh reads twice the value on 4.3. See :doc:`api_reference/attachment/hullLength`.

- **Before:**

  .. fragment: 4.2 code; attachment is a mesh attachment the app holds
  .. code-block:: lua

      local hullNumbers = attachment.hullLength * 2

- **After:**

  .. code-block:: lua

      local attachment = skeleton:findSlot("torso").attachment
      local hullNumbers = attachment.hullLength

  on the 4.3 line.
- **What to change:** drop the ``* 2`` where you turn ``hullLength`` into a count of numbers.
- **CHANGELOG:** `4.3 line`_, "attachment.hullLength counts numbers, not vertices".

Volume and balance of custom events in ``.json`` data
-----------------------------------------------------

A custom event key in ``.json`` data that sets no volume or balance of its own reports ``1`` and ``0`` on the 4.2
line, as the 4.2 runtime reads it, and the event's default volume and balance on the 4.3 line.

- **Before:**

  .. fragment: 4.2 listener body; event is the listener's argument
  .. code-block:: lua

      local volume = event.volume -- 1 on the 4.2 line for a key without its own volume

- **After:** ``event.volume`` and ``event.balance`` are the event's defaults from the Spine editor for such a key.
- **What to change:** set the volume and balance on the key in Spine if the event's defaults are not what you want.
- **CHANGELOG:** `4.2 line`_, "A custom event key in .json data without its own volume or balance reports 1 and 0".

Version strings
---------------

``spine.version`` is ``"3.0.0"`` and ``spine.runtimeVersion`` is ``"4.3"`` on the 4.3 line (``"2.0.0"`` and
``"4.2"`` on the 4.2 line).

- **Before:**

  .. fragment: partial 4.2 code; the app's 4.2-only branch
  .. code-block:: lua

      if spine.runtimeVersion == "4.2" then

- **After:**

  .. code-block:: lua

      print(spine.version, spine.runtimeVersion)

- **What to change:** update any check that compares these strings.
- **CHANGELOG:** `both lines`_, "Added spine.version and spine.runtimeVersion, without the v the load banner prints".
