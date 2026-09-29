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

Using Skin Name
...............

.. code-block:: lua

   -- Apply a predefined skin by name
   hero:setSkin("warrior")

Using Custom Skin Object
.........................

.. code-block:: lua

   -- Create and apply a custom skin
   local customSkin = skeleton:createSkin("myAvatar")
   customSkin:addSkin("base")
   customSkin:addSkin("armor")
   
   skeleton:setSkin(customSkin)

Switch Between Skins
.....................

.. code-block:: lua

   -- Switch between different character appearances
   if powerupActive then
       skeleton:setSkin("powered")
   else
       skeleton:setSkin("normal")
   end