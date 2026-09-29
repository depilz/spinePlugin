===================================
skin.name
===================================

| **Type:** ``property``
| **Value:** ``string``
| **See also:** :doc:`index`, :doc:`getName`

Overview:
.........

Read-only property that returns the name of the skin. Writing it raises
``SpineSkin: property 'name' is read-only``.

Example:
--------

.. code-block:: lua

   local customSkin = skeleton:createSkin("myAvatar")
   print(customSkin.name)  -- Output: "myAvatar"
   
   local currentSkin = skeleton:getSkin()
   if currentSkin then
       print("Current skin:", currentSkin.name)
   end

