===================================
skeleton:createSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setSkin`, :doc:`getSkin`, :doc:`registerSkin`, :doc:`../skin/index`

Overview:
.........

Creates a new custom Skin object that can be used to combine attachments from multiple existing skins. This enables mix-and-match character customization where different body parts can use different skins.

The created skin is initially empty and must have attachments added to it using the :doc:`../skin/addSkin` or :doc:`../skin/copySkin` methods.

Syntax:
--------

.. code-block:: lua

   local customSkin = skeleton:createSkin(skinName)
    
- ``skinName`` *(required)*:
    ``string`` – The name for the new custom skin. This name can be used with :doc:`registerSkin` to make the skin reusable.

Returns:
--------

``Skin`` – A new Skin object that can be customized with attachments from other skins.

Example:
--------

Basic Usage
...........

.. code-block:: lua

   -- Create a new custom skin
   local customSkin = skeleton:createSkin("myAvatar")
   
   -- Add attachments from different skins
   customSkin:addSkin("soldier")  -- Add all soldier attachments
   customSkin:addSkin("warrior")  -- Add all warrior attachments
   
   -- Apply the combined skin
   skeleton:setSkin(customSkin)

Mix and Match Character Parts
..............................

.. code-block:: lua

   -- Create custom avatar combining different skins
   local avatar = skeleton:createSkin("customAvatar")
   
   -- Combine parts from different character skins
   avatar:addSkin("base")      -- Base body
   avatar:addSkin("soldier")   -- Soldier equipment
   avatar:addSkin("knight")    -- Knight armor
   
   -- Apply and register for reuse
   skeleton:setSkin(avatar)
   skeleton:registerSkin(avatar)
   
   -- Later, use by name
   skeleton:setSkin("customAvatar")

Notes:
--------

- The custom skin is owned by the Lua side until registered with :doc:`registerSkin`
- Custom skins can combine any number of existing skins
- Later additions with :doc:`../skin/addSkin` will overwrite duplicate attachments
- Use :doc:`../skin/copySkin` if you need independent copies of attachments

