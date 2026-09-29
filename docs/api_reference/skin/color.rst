skin.color
==========

Gets or sets the editor skin color. This is metadata exported from the Spine
editor. It is **not multiplied into rendered attachment colors** and does not tint
or fade the skeleton.

Only a custom skin (from :doc:`../skeleton/createSkin`) can be written; writing it on a data skin
raises, because data skins are read-only (see :doc:`index`).

.. code-block:: lua

   local skin = skeleton:createSkin("tinted")
   skin.color = {r = 1, g = 0.5, b = 0.5, a = 1}

For rendered color changes, use :doc:`../skeleton/slot/color` or
:doc:`../skeleton/setFillColor`. Attachment-object colors are shared by users of
that object; see :doc:`/attachments-and-skins`.
