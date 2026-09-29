===================================
skeleton:createSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setSkin`, :doc:`getSkin`, :doc:`../skin/index`

Overview:
.........

Creates a new custom Skin object that can be used to combine attachments from multiple existing skins. This enables mix-and-match character customization where different body parts can use different skins.

The created skin is initially empty and must have attachments added to it using the :doc:`../skin/addSkin` or :doc:`../skin/copySkin` methods.

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

Syntax:
--------

.. fragment: syntax line; skinName is a placeholder
.. code-block:: lua

   local customSkin = skeleton:createSkin(skinName)

- ``skinName`` *(required)*:
    ``string`` – The name for the new custom skin.

Returns:
--------

``Skin`` – A new Skin object that can be customized with attachments from other skins.

Example:
--------

Basic Usage
...........

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Create a new custom skin
   local customSkin = girl:createSkin("myAvatar")

   -- Add attachments from different skins
   customSkin:addSkin("skin-base")              -- Add the body
   customSkin:addSkin("clothes/hoodie-orange")  -- Add the hoodie

   -- Apply the combined skin
   girl:setSkin(customSkin)

Mix and Match Character Parts
..............................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Create custom avatar combining different skins
   local avatar = girl:createSkin("customAvatar")

   -- Combine parts from different character skins
   avatar:addSkin("skin-base")                -- Base body
   avatar:addSkin("hair/brown")               -- Hair
   avatar:addSkin("clothes/dress-green")      -- Dress
   avatar:addSkin("accessories/hat-red-yellow")  -- Hat

   -- Apply the combined skin
   girl:setSkin(avatar)

Notes:
--------

- The custom skin is owned by the Lua side; an applied custom skin is retained automatically
- Custom skins can combine any number of existing skins
- Later additions with :doc:`../skin/addSkin` will overwrite duplicate attachments
- Use :doc:`../skin/copySkin` if you need independent copies of attachments

