===================================
skin:getName()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`name`, :doc:`/naming`

Overview:
.........

``skin:getName()`` is an alias of :doc:`name` (``skin.name``): it returns the skin's name. Both names work on both plugin lines and
stay supported; :doc:`/naming` explains which name is canonical. The full description is on :doc:`name`.

Example:
--------

.. code-block:: lua

   local customSkin = hero:createSkin("myAvatar")
   print(customSkin:getName(), customSkin.name)  -- myAvatar  myAvatar
