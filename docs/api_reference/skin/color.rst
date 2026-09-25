skin.color
==========

Gets or sets the editor skin color. This is metadata exported from the Spine
editor. It is **not multiplied into rendered attachment colors** and does not tint
or fade the skeleton.

.. code-block:: lua

   local skin = skeleton:getSkin()
   if skin then
       skin.color = {r = 1, g = 0.5, b = 0.5, a = 1}
   end

For rendered color changes, use :doc:`../skeleton/slot/color` or
:doc:`../skeleton/setFillColor`. Attachment-object colors are shared by users of
that object; see :doc:`/attachments-and-skins`.
