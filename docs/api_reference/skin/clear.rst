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

.. fragment: syntax line; skin is a placeholder
.. code-block:: lua

   skin:clear()

Returns:
--------

``Skin`` – The skin itself, so calls can be chained.

Raises a Lua error, and changes nothing, when the skin is a data skin: data skins are read-only
(see :doc:`index`).

Example:
--------

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local avatar = girl:createSkin("avatar")
   avatar:addSkin("skin-base"):addSkin("accessories/hat-red-yellow")
   girl:setSkin(avatar)

   -- Later: rebuild the same skin with other parts, then reapply it
   avatar:clear():addSkin("skin-base"):addSkin("accessories/hat-pointy-blue-yellow")
   girl:setSkin(avatar)

Notes:
--------

- Attachments already displayed by slots stay displayed until the skin is reapplied or the slots change
- Reapply the skin with :doc:`../skeleton/setSkin` after rebuilding it, to refresh the bones and constraints it enables
