Removing skeletons
==================

A skeleton returned by :doc:`api_reference/spine/create` is a Solar2D display
object. Remove it like any other display object: ``skeleton:removeSelf()``,
``display.remove(skeleton)``, or by removing a parent group or a composer scene.
All of these end the same way. The skeleton goes through a short dispose window,
and its native memory is freed on the next frame.

The dispose window
------------------

1. **Removal.** After ``skeleton:removeSelf()`` or ``display.remove(skeleton)``,
   the skeleton stops updating, drawing and dispatching animation events through
   indexing at once.
   An animation listener that removes its own skeleton ends the current event
   drain: the listeners after it do not get that event (see
   :doc:`api_reference/spine/event`), and no further events are dispatched. A
   ``removeSelf()`` inside a ``"spine"`` listener added with
   ``addEventListener`` does not stop the rest of that one ``dispatchEvent``.
   Indexing the object now only resolves the event-dispatcher keys
   (``addEventListener``, ``removeEventListener``, ``hasEventListener``,
   ``dispatchEvent``, ``respondsToEvent``) and the helpers Solar2D's
   ``addEventListener`` and ``removeEventListener`` call on the object
   (``getOrCreateTable``, ``didRemoveListener``, ``_setHasListener``), so adding
   and removing listeners keeps working, in ``finalize`` listeners too. Every
   other key reads ``nil``, including ``removeSelf`` and ``numChildren``. So the
   usual guard keeps working:

   .. code-block:: lua

      local deltaTime = 16 -- milliseconds since the last frame
      if skeleton.removeSelf then
          skeleton:updateState(deltaTime)
          if skeleton.removeSelf then -- a listener may have removed it
              skeleton:draw()
          end
      end

2. **Finalize.** When Solar2D finalizes the object (for a parent removal, this is
   the first point the plugin sees), your own ``finalize`` listeners run. The
   wrappers you hold (bones, slots, track entries, ...) and stored methods still
   work inside them. After a parent removal, method calls on the skeleton itself
   work there too; after ``skeleton:removeSelf()`` the object only answers the
   event-dispatcher keys, as in step 1.

3. **After finalize.** Solar2D then strips the display object's metatable. From
   this point every access through a held wrapper raises
   ``<Type> belongs to a removed skeleton``, where ``<Type>`` is one of ``Slot``,
   ``Bone``, ``IK constraint``, ``Physics constraint``, ``Track entry``, ``Fill`` or
   ``Effect``. A skeleton method you stored earlier (``local set = skeleton.setAnimation``)
   raises ``Skeleton belongs to a removed skeleton``.

   A plain method call such as ``skeleton:setAnimation(1, "idle", true)`` does
   **not** show that message: ``skeleton.setAnimation`` is ``nil`` on a removed
   object, so Lua raises its usual ``attempt to call method 'setAnimation' (a nil
   value)``. The removal-specific message only appears through stored methods and
   wrappers.

   Before this point, in the handler that removed the skeleton, stored methods and
   wrappers still work on the live skeleton: a stored ``setAnimation`` changes the
   animation state and returns, a stored ``updateState`` or ``draw`` does part of
   its work, and wrappers read as before. The removal error only starts once
   Solar2D strips the metatable.

4. **Next frame.** A one-shot ``Runtime`` ``enterFrame`` listener frees the native
   skeleton, animation state and meshes. It only frees memory; it never updates,
   draws or dispatches events. Wrappers and stored methods keep raising after
   this. The skeleton's reference to its display object (``event.target``) is
   released here too.

Skin and attachment wrappers are not tied to one skeleton: they stay usable after
the skeleton is removed (see :doc:`attachments-and-skins`).

Removed versus live skeletons
-----------------------------

The ``false``/boolean results are for **live** skeletons only:

- On a live skeleton, :doc:`api_reference/skeleton/setAnimation` and
  :doc:`api_reference/skeleton/addAnimation` return ``false`` when the animation
  does not exist, and :doc:`api_reference/skeleton/findAnimation` returns a
  boolean.
- On a removed skeleton, the same calls raise, as described above. Do not use
  their return value to detect removal; check ``skeleton.removeSelf`` instead.

Writing properties
------------------

.. Tested by tests/lifecycle/t40_write_after_remove (removed, parent, finalized).

What a property write does on a removed skeleton depends on how far the removal
got:

- After ``skeleton:removeSelf()`` or ``display.remove(skeleton)``, the plugin hands
  every write, such as ``skeleton.timeScale = 2``, to the display group, as for any
  other display object. It never raises, and the skeleton does not change: the
  animation state keeps its own ``timeScale``, and
  :doc:`api_reference/skeleton/physicsTimeScale` is not checked (``-1`` does not
  raise).
- After a parent group removal, the skeleton stays live until Solar2D finalizes it
  at the end of the frame, so a write before that still changes the skeleton.
- After finalize, the skeleton is a plain Lua table and the write sets a plain
  field on it.

A write cannot tell you whether the skeleton was removed: check
``skeleton.removeSelf`` first, as in the guard above.

Track entries
-------------

A track entry is only valid while the animation state still owns it. Read
:doc:`api_reference/skeleton/trackEntry/isValid` before using an entry you kept
from an earlier frame. Any other key on an entry that has finished or was
returned to the pool raises
``Track entry is no longer valid (finished or disposed); check entry.isValid``.
On a removed skeleton the entry raises ``Track entry belongs to a removed skeleton``.

Listener errors
---------------

An error raised by an animation listener (the one passed to
:doc:`api_reference/spine/create`, an entry's
:doc:`api_reference/skeleton/trackEntry/onComplete`, or a ``"spine"`` listener
added with ``addEventListener``) no longer disappears. The plugin runs each of
them through Solar2D's ``CoronaLuaDoCall``, so Solar2D reports the error the way
it reports any other listener error (a traceback in the console, and the
``unhandledError`` runtime event). The call that triggered the listener
(``updateState``, ``setAnimation``, ...) does not raise and carries on.

Errors raised by an injection listener (see :doc:`api_reference/skeleton/inject`)
still propagate out of :doc:`api_reference/skeleton/draw`.

Side effects of the finalize hook
---------------------------------

The plugin adds a ``finalize`` listener to every skeleton it creates, and a
``Runtime`` ``enterFrame`` listener while a removal is pending. As a result:

- ``skeleton._functionListeners`` exists even if you never added a listener;
- ``skeleton:respondsToEvent("finalize")`` returns ``true``;
- if your app removes **all** ``Runtime`` listeners while a removal is pending, the
  pending skeletons are not freed on that frame. They stay queued until the next
  skeleton removal re-registers the listener, and are freed with it.

If there is no ``Runtime`` object (a host other than Solar2D), or the listener
cannot be registered, the skeleton is freed during ``finalize`` instead. Wrappers
raise from that point on; finalize itself never raises.

Calling a plugin method late
----------------------------

Code that keeps a removed skeleton and calls into it after finalize (for example,
a stored ``removeSelf`` run as a late cleanup) gets the
``Skeleton belongs to a removed skeleton`` error described above. Earlier plugin
versions could abort the engine in this case. Guard late cleanups with
``if skeleton.removeSelf then ... end`` or ``display.remove(skeleton)``.

This only covers plugin methods. A Solar2D display method you stored before
removal (``local toFront = skeleton.toFront``) is outside the plugin: calling it
on a removed skeleton can abort the engine, and the plugin cannot prevent it.

Migrating an app
----------------

Apps written against earlier plugin versions should check these changes:

- ``event.target`` in animation events is now the display object returned by
  ``spine.create()``, so ``event.target == skeleton`` holds. It used to be an
  internal userdata.
- Wrappers of a removed skeleton raise instead of reading freed memory. Drop
  references to bones, slots, constraints, fills and track entries when you remove
  the skeleton.
- Track entries raise once they are finished or pooled. Check ``entry.isValid``
  before using a stored entry.
- Animation listener errors are now reported by Solar2D instead of being
  silently dropped.
- ``numChildren`` is ``nil`` on a removed skeleton, like every other non-event key.
- Removal no longer frees memory at once. It is freed on the next frame, so
  memory measurements taken in the same frame still include the skeleton.
- ``spine.loadAtlas()`` raises ``Failed to load texture: <path>`` when a page
  texture cannot be loaded, and keeps nothing in memory.
- Every animation event has ``event.name == "spine"``. A custom event has
  ``event.phase == "event"`` and its name in ``event.event``; it used to arrive
  with its name in ``event.name`` and no ``phase``. Its ``int``, ``float``,
  ``string``, ``volume`` and ``balance`` are the key's own values, and
  ``event.time`` is the key's time in milliseconds (see
  :doc:`api_reference/spine/event`).
- ``skeleton:addEventListener("spine", listener)`` now receives the animation
  events, after the listener passed to ``spine.create()``.
- ``skeleton.tracks`` is a new plain table on each read, with ``false`` for an
  empty track (see :doc:`api_reference/skeleton/tracks`).
- Writing an unknown or read-only key on a track entry raises instead of being
  ignored.
- ``skeleton.isActive`` is ``false`` once no track has a current entry (see
  :doc:`api_reference/skeleton/isActive`). A loop that updates and draws only
  while ``isActive`` is ``true`` stops once every track is cleared or mixed out.
- ``getSize().offsetY`` is ``getBounds().yMin``; it used to be ``-yMin``.
- Physics steps in ``updateState``, and ``draw`` only poses (see
  :doc:`api_reference/skeleton/updateState`). Code that calls ``draw`` without
  ``updateState``, or ``updateState`` several times per ``draw``, moves physics
  differently than before.
