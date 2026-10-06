===================================
skeleton:setListener()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`../spine/event`

Overview
--------

Sets or clears the animation listener for this skeleton, the one passed to :doc:`../spine/create`.

It only swaps that one function. ``"spine"`` listeners added with ``skeleton:addEventListener`` and
:doc:`trackEntry/onComplete` functions keep receiving events. Calling it inside a listener takes effect from the next
event.

Syntax
------

.. code-block:: lua

   skeleton:setListener(listenerOrNil)

Parameters
----------

- ``listenerOrNil`` *(required)*:
    ``function`` or ``nil`` – Function to receive events, or ``nil`` to clear listener.

Example
-------

.. code-block:: lua

   spineboy:setListener(function(event)
       if event.phase == "completed" then
           print("Completed:", event.animation)
       end
   end)

   -- Later, remove listener:
   spineboy:setListener(nil)
