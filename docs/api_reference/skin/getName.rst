===================================
skin:getName()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`name`

Overview:
.........

Returns the name of the skin.

Syntax:
--------

.. code-block:: lua

   local name = skin:getName()

Returns:
--------

``string`` – The skin's name.

Example:
--------

.. code-block:: lua

   local customSkin = skeleton:createSkin("myAvatar")
   print(customSkin:getName())  -- Output: "myAvatar"
   
   local currentSkin = skeleton:getSkin()
   if currentSkin then
       print("Active skin:", currentSkin:getName())
   end

Notes:
--------

This is equivalent to accessing the ``name`` property directly: ``skin.name``

