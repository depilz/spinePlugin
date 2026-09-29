===================================
skeleton:setSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getSkins`, :doc:`createSkin`, :doc:`getSkin`

Overview:
.........

Sets the skeleton's current skin. Accepts a skin name (string), a Skin object of the same skeleton data
(a data skin from :doc:`findSkin` or a custom skin created with :doc:`createSkin`), or ``nil`` to clear the skin.

By default, applying a skin resets slots to setup pose, including attachments,
slot colors, and draw order. Pass ``false`` as the second argument to skip this
extra reset. Spine's normal skin-switch attachment replacements still occur.
Animations may change attachments on the next update. See :doc:`/attachments-and-skins`.

Syntax:
--------

.. code-block:: lua

   skeleton:setSkin(skinNameOrObject)
   skeleton:setSkin(skinNameOrObject, false)
   skeleton:setSkin(nil)

- ``skinNameOrObject`` *(required)*:
    ``string``, ``Skin`` or ``nil`` – The name of an existing skin, a Skin object, or ``nil`` to clear the
    skin: attachment lookups then use only the default skin (so the setup-pose reset shows the default skin's
    attachments), and :doc:`getSkin` returns ``nil``.

- ``resetSlots`` *(optional)*:
    ``boolean`` – Defaults to ``true``. Set to ``false`` to skip the setup-pose reset.

The skin must belong to the same skeleton data. An unknown skin name, a wrong type or a skin of other
skeleton data raises a Lua error. Applied custom skins are retained automatically; a custom skin cannot be
applied by name, pass the Skin object.

Skin bones: after ``setSkin``, a slot whose bone is a skin bone the applied skin does not enable does
**not** raise when it still shows an attachment: the attachment is not updated and not drawn. Apply the
skin that enables the bone (or a custom skin built with that skin's bones) to draw it.

Example:
--------

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

Using Skin Name
...............

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Apply a predefined skin by name
   girl:setSkin("full-skins/girl")

Using Custom Skin Object
.........................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Create and apply a custom skin
   local customSkin = girl:createSkin("myAvatar")
   customSkin:addSkin("skin-base")
   customSkin:addSkin("clothes/hoodie-orange")

   girl:setSkin(customSkin)

Switch Between Skins
.....................

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Switch between different character appearances
   local function setPowerUp(powerupActive)
       if powerupActive then
           girl:setSkin("full-skins/girl-blue-cape")
       else
           girl:setSkin("full-skins/girl")
       end
   end
   setPowerUp(true)