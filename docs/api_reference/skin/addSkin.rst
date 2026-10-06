===================================
skin:addSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`copySkin`, :doc:`../skeleton/createSkin`

Overview
--------

Adds all attachments from another skin to this skin. Attachments are shared by reference (not copied), making this operation fast and memory-efficient.

If an attachment with the same slot and name already exists in this skin, it will be replaced by the attachment from the other skin.

Syntax
------

.. fragment: syntax line; skin and skinNameOrObject are placeholders
.. code-block:: lua

   skin:addSkin(skinNameOrObject)

Parameters
----------

- ``skinNameOrObject`` *(required)*:
    ``string`` or ``Skin`` – Either the name of an existing skin or a Skin object of the same skeleton data.
    A name finds only the skeleton data's skins, so a skin made with
    ``skeleton:createSkin()`` must be passed as the Skin object.

Return value
------------

``Skin`` – The skin itself, so calls can be chained.

Raises a Lua error, and changes nothing, when this skin is a data skin (read-only), or when the
other skin is not found, has the wrong type or belongs to different skeleton data.

Example
-------

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

Combine Multiple Skins
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Create a custom skin
   local avatar = girl:createSkin("myCharacter")

   -- Add attachments from multiple skins
   avatar:addSkin("skin-base")              -- Base body
   avatar:addSkin("clothes/hoodie-orange")  -- Clothes
   avatar:addSkin("accessories/cape-red")   -- Cape accessory

   -- Apply the combined skin
   girl:setSkin(avatar)

Layer Skins
~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Build up a character by layering skins
   local character = girl:createSkin("layered")

   -- Add base, then layer customization on top
   character:addSkin("skin-base")
            :addSkin("hair/short-red")
            :addSkin("eyes/green")
            :addSkin("legs/pants-jeans")

   girl:setSkin(character)

Notes
-----

- Attachments are shared, not copied (references only)
- Later additions overwrite duplicate slot/attachment combinations
- Very fast operation - suitable for runtime character customization
- For independent copies, use :doc:`copySkin` instead
- Raises on a data skin: data skins are read-only (see :doc:`index`)
- Raises when the skin is not found; use :doc:`../skeleton/findSkin` to check first
