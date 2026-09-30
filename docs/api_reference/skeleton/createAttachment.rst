=======================================
skeleton:createAttachment()
=======================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`createSkin`, :doc:`../skin/setAttachment`, :doc:`../attachment/region`

Overview:
.........

Creates a new region attachment that shows a region of the skeleton's own atlas (the atlas its skeleton data was
loaded with). Put it in a custom skin with :doc:`../skin/setAttachment` or show it directly with
:doc:`slot/attachment`. No animation of the skeleton data drives it: it is not one of the data's attachments.

Syntax:
--------

.. fragment: syntax line; the region and attachment names are placeholders
.. code-block:: lua

   local attachment = skeleton:createAttachment({ region = regionName, name = attachmentName })

- ``region`` *(required)*:
    ``string`` – The name of a region in the skeleton's atlas. A name the atlas does not have raises
    ``Region not found in the skeleton's atlas: <name>``.
- ``name`` *(required)*:
    ``string`` – The attachment's name.
- ``width``, ``height`` *(optional)*:
    ``number`` – The attachment's size. Default: the region's original size (``originalWidth``,
    ``originalHeight`` of :doc:`../attachment/region`).
- ``x``, ``y``, ``rotation``, ``scaleX``, ``scaleY`` *(optional)*:
    ``number`` – The attachment's offset from its bone, rotation in degrees and scale. Default: ``0``, ``0``,
    ``0``, ``1``, ``1``.

A missing or empty ``name`` and a non-number geometry field raise.

Returns:
--------

``Attachment`` – A new region attachment (``type == "region"``) of the skeleton's skeleton data.

Example:
--------

.. code-block:: lua

   local badge = skeleton:createAttachment({ region = "crosshair", name = "badge", scaleX = 0.5, scaleY = 0.5 })

   local skin = skeleton:createSkin("badged")
   skin:addSkin("default"):setAttachment("gun", "gun", badge)
   skeleton:setSkin(skin)
