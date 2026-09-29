===================================
skin:clear()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`removeAttachment`, :doc:`setAttachment`

Overview:
.........

Removes every attachment entry from the skin, and clears the bones and constraints the skin
enables. The skin keeps its name and color and can be filled again, for example to rebuild an
avatar in place.

Syntax:
--------

.. code-block:: lua

   skin:clear()

Returns:
--------

``Skin`` – The skin itself, so calls can be chained.

Raises a Lua error, and changes nothing, when the skin is a data skin: data skins are read-only
(see :doc:`index`).

Example:
--------

.. code-block:: lua

   local avatar = skeleton:createSkin("avatar")
   avatar:addSkin("body"):addSkin("hat")
   skeleton:setSkin(avatar)

   -- Later: rebuild the same skin with other parts, then reapply it
   avatar:clear():addSkin("body"):addSkin("helmet")
   skeleton:setSkin(avatar)

Notes:
--------

- Attachments already displayed by slots stay displayed until the skin is reapplied or the slots change
- Reapply the skin with :doc:`../skeleton/setSkin` after rebuilding it, to refresh the bones and constraints it enables
