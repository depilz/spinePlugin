=======================================
attachment:copy()
=======================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`../skin/setAttachment`, :doc:`../skin/copySkin`

Overview:
.........

Returns a new attachment object with this attachment's properties. Attachments are shared by
the skins and skeletons that use them, so a property write changes every user of the object; a
copy lets you change one skin's or one skeleton's attachment on its own. The copy belongs to the
same skeleton data and is not part of any skin until you put it in one.

The copy follows Spine's attachment copy: a linked mesh copies as a linked mesh of the same
parent mesh.

Syntax:
--------

.. fragment: syntax line; attachment is a placeholder
.. code-block:: lua

   local copy = attachment:copy()

Returns:
--------

``Attachment`` – The new attachment. ``copy == attachment`` is ``false``.

Example:
--------

.. code-block:: lua

   local skin = skeleton:createSkin("redGun")
   local gun = skeleton:findSkin("default"):getAttachment("gun", "gun")

   local redGun = gun:copy()
   redGun.color = {r = 1, g = 0, b = 0, a = 1}   -- the "default" skin's gun keeps its color

   skin:addSkin("default"):setAttachment("gun", "gun", redGun)
   skeleton:setSkin(skin)
