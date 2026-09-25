===================================
skeleton:setSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getSkins`, :doc:`createSkin`, :doc:`getSkin`

Overview:
.........

Sets the skeleton's current skin. Accepts either a skin name (string) or a custom Skin object created with :doc:`createSkin`.

By default, applying a skin resets slots to setup pose, including attachments,
slot colors, and draw order. Pass ``false`` as the second argument to skip this
extra reset. Spine's normal skin-switch attachment replacements still occur.
Animations may change attachments on the next update. See :doc:`/attachments-and-skins`.

Syntax:
--------

.. code-block:: lua

   skeleton:setSkin(skinNameOrObject)
   skeleton:setSkin(skinNameOrObject, false)
    
- ``skinNameOrObject`` *(required)*:
    ``string`` or ``Skin`` – Either the name of an existing skin, or a custom Skin object.

- ``resetSlots`` *(optional)*:
    ``boolean`` – Defaults to ``true``. Set to ``false`` to skip the setup-pose reset.

The skin must belong to the same skeleton data. Applied custom skins are retained
automatically; registration is only needed to use them by name.

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