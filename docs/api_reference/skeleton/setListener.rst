===================================
skeleton:setListener()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`../spine/event`

Overview:
.........

Sets or clears the animation state listener for this skeleton.

Syntax:
--------

.. code-block:: lua

   skeleton:setListener(listenerOrNil)

- ``listenerOrNil`` *(required)*:
    ``function | nil`` – Function to receive events, or ``nil`` to clear listener.

Example:
--------

.. code-block:: lua

   hero:setListener(function(event)
       if event.name == "spine" and event.phase == "completed" then
           print("Completed:", event.animation)
       end
   end)

   -- Later, remove listener:
   hero:setListener(nil)
