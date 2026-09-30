===================================
slot.appliedAttachment
===================================

| **Type:** ``Attachment`` or ``nil`` (read-only)
| **See also:** :doc:`index`, :doc:`attachment`, :doc:`../../attachment/index`

Overview:
.........

The attachment the renderer draws for this slot, or ``nil`` when it draws none. Spine 4.3 keeps two poses per slot:
the pose that :doc:`attachment` reads and writes, and the applied pose built from it each frame, which constraints
may change. A slider constraint whose animation keys this slot's attachment changes only the applied pose, so there
``appliedAttachment`` can differ from ``slot.attachment``. Without such a constraint the two are the same.

The value follows the last ``updateState`` or draw. Each read returns a new Attachment object for the same attachment.

``appliedAttachment`` is read-only. Writing it raises
``SpineSlot: property 'appliedAttachment' is read-only; it is the attachment the renderer draws — set slot.attachment``.
Reading or writing it on a slot of a removed skeleton raises ``Slot belongs to a removed skeleton``
(see :doc:`/lifecycle`).

Example:
--------

.. code-block:: lua

   local slot = spineboy:getSlot("gun")
   local drawn = slot.appliedAttachment
   if drawn ~= slot.attachment then
      print("A constraint shows", drawn and drawn.name, "instead of", slot.attachment and slot.attachment.name)
   end
