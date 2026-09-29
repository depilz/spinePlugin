===================================
skeleton:getSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`setSkin`, :doc:`createSkin`, :doc:`../skin/index`, :doc:`/naming`

Overview:
.........

Returns the skeleton's currently active Skin object. This allows you to inspect the current skin. A data
skin is read-only; the applied custom skin can be modified (see :doc:`../skin/index`).

``getSkin`` takes no argument: passing one raises. To look a skin up by name, use :doc:`findSkin`.

Syntax:
--------

.. code-block:: lua

   local currentSkin = skeleton:getSkin()

Returns:
--------

``Skin`` or ``nil`` – The currently active Skin object, or nil if no skin is set.

Example:
--------

Get Current Skin
................

.. code-block:: lua

   -- Get the current skin
   local skin = skeleton:getSkin()

   if skin then
       print("Current skin:", skin.name)

       -- Inspect attachments
       local attachments = skin:getAttachments()
       print("Number of attachments:", #attachments)
   end

Clone Current Skin
..................

.. code-block:: lua

   -- Get current skin and make a modified copy
   local currentSkin = skeleton:getSkin()

   if currentSkin then
       local newSkin = skeleton:createSkin("modified")
       newSkin:copySkin(currentSkin)

       -- Add more attachments
       newSkin:addSkin("accessories")

       skeleton:setSkin(newSkin)
   end

