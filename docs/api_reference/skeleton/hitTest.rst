===================================
skeleton:hitTest()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getBounds`, :doc:`bone/setWorldPosition`

Overview:
.........

Tells which bounding-box attachments (Spine "hit areas") of the skeleton contain a point, top-most first.

``x`` and ``y`` are **content coordinates**, like a touch event's ``event.x`` and ``event.y``. ``hitTest`` converts
them once with ``skeleton:contentToLocal()`` to skeleton space: the skeleton object's local coordinates, with y
growing downwards, the space of :doc:`bone/worldX` and :doc:`bone/worldY`. The skeleton object's position, scale and
rotation and those of its parent groups are taken into account.

The bounding boxes are tested in **draw order, last drawn first**, so a draw order changed by an animation changes
the order of the hits. This differs from Spine's ``SkeletonBounds.containsPoint``, which returns the first box in
slot order.

Without a listener, ``hitTest`` returns the hit table of the top-most box containing the point, or ``nil``. With a
listener, it calls the listener with a hit table for every box containing the point, top-most first, like touch
propagation: a listener that returns ``true`` stops the walk. ``hitTest`` then returns ``true`` if a listener stopped
the walk, else ``false``. The walk also ends, with no further listener call, when a listener removes the skeleton or
changes its skin or any slot's attachment. An error raised in the listener reaches the ``hitTest`` caller.

Only geometry counts: a slot whose bone is inactive (for example a skin bone while its skin is not set) is skipped,
and the slot's current attachment is used. ``isVisible = false``, alpha 0 and hidden slots do **not** prevent a hit,
unlike Solar2D touch.

``hitTest`` reads the current world transform, the one recalculated by ``spine.create()``, :doc:`updateState` and
:doc:`draw`. A bone moved with :doc:`bone/setWorldPosition` or ``bone.x`` is hit at its new position after the next
``updateState`` or ``draw``.

After :doc:`split`, split slots are still tested in the skeleton object's space and draw order. They hit correctly
only while their split group has the same content transform as the skeleton object; move the split group and its
bounding boxes are still tested where the skeleton object would draw them.

Raises when the skeleton was removed, when ``x`` or ``y`` is not a number, and when ``listener`` is neither a
function nor ``nil``.

Syntax:
--------

.. code-block:: lua

   local hit = skeleton:hitTest(x, y)
   local handled = skeleton:hitTest(x, y, listener)

- ``x``, ``y`` *(required)*:
    ``number`` – The point in content coordinates.

- ``listener`` *(optional)*:
    ``function`` – Called with a hit table for each box containing the point, top-most first. Return ``true`` to
    stop.

Hit table:
----------

- ``slotName``: ``string`` – The name of the bounding box's slot.

- ``attachmentName``: ``string`` – The name of the bounding-box attachment.

- ``target``: the skeleton object.

- ``x``, ``y``: ``number`` – The content coordinates passed to ``hitTest``.

- ``localX``, ``localY``: ``number`` – The same point in skeleton space.

Example:
--------

Top-most hit
............

.. code-block:: lua

   local function onTouch(event)
       if event.phase == "began" then
           local hit = skeleton:hitTest(event.x, event.y)
           if hit and hit.attachmentName == "head" then
               print("Head tapped")
           end
       end
       return true
   end
   skeleton:addEventListener("touch", onTouch)

Every hit
.........

.. code-block:: lua

   local function onTouch(event)
       if event.phase == "began" then
           skeleton:hitTest(event.x, event.y, function(hit)
               print("Hit", hit.slotName, hit.attachmentName)
               if hit.slotName == "shield" then
                   return true -- stop here: the boxes below are not reported
               end
           end)
       end
       return true
   end
   skeleton:addEventListener("touch", onTouch)
