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

.. code-block:: lua

   local copy = attachment:copy()

Returns:
--------

``Attachment`` – The new attachment. ``copy == attachment`` is ``false``.

Example:
--------

.. code-block:: lua

   local skin = skeleton:createSkin("redHat")
   local hat = skeleton:findSkin("default"):getAttachment("head", "hat")

   local redHat = hat:copy()
   redHat.color = {r = 1, g = 0, b = 0, a = 1}   -- the "default" skin's hat keeps its color

   skin:addSkin("default"):setAttachment("head", "hat", redHat)
   skeleton:setSkin(skin)
