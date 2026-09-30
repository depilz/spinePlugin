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

.. only:: spine43

   **Another region.** ``attachment:copy{ region = "<name>" }`` returns a copy that shows that region of the
   skeleton's own atlas; the original keeps its region. It works for region and mesh attachments with a single-frame
   sequence:

   - a region copy keeps its size and position, so the region is fitted to the same quad;
   - a mesh copy keeps its own UVs, so the new region must be packed with the same shape as the old one, or the
     image stretches.

   The copy is still driven by the original's animations: its sequence and deform timelines apply to the copy too.
   A region name the atlas does not have raises ``Region not found in the skeleton's atlas: <name>``; a multi-frame
   sequence raises ``SpineAttachment: copy{ region } needs a single-frame attachment; '<name>' has a <n>-frame
   sequence``, and any other attachment type raises
   ``SpineAttachment: copy{ region } needs a region or mesh attachment, not a <type> attachment``.
   ``attachment.region`` reads the region an attachment shows.

Syntax:
--------

.. fragment: syntax line; attachment is a placeholder
.. code-block:: lua

   local copy = attachment:copy()

.. only:: spine43

   .. fragment: syntax line; attachment and regionName are placeholders
   .. code-block:: lua

      local copy = attachment:copy({ region = regionName })

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

.. only:: spine43

   .. code-block:: lua

      -- the front bracer showing the crosshair image, on this skeleton only
      local skin = skeleton:createSkin("crosshairBracer")
      local bracer = skeleton:findSlot("front-bracer").attachment
      skin:addSkin("default"):setAttachment("front-bracer", "front-bracer", bracer:copy({ region = "crosshair" }))
      skeleton:setSkin(skin)
