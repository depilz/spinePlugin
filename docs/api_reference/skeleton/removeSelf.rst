===================================
skeleton:removeSelf()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`/lifecycle`

Overview
--------

Removes the skeleton, like
`object:removeSelf() <https://docs.coronalabs.com/api/type/DisplayObject/removeSelf.html>`_ on any display object;
``display.remove(skeleton)`` does the same. The skeleton overrides the display group's ``removeSelf``: it marks the
skeleton removed, removes the meshes of any :doc:`split`, then calls the group's own ``removeSelf``.

A removed skeleton answers only the event-dispatcher keys; every other key reads ``nil``, ``removeSelf`` included, so
calling ``skeleton:removeSelf()`` a second time raises Lua's ``attempt to call method 'removeSelf' (a nil value)``.
Use ``display.remove(skeleton)``, or check ``if skeleton.removeSelf then``, where the skeleton may already be
removed. :doc:`/lifecycle` describes what happens after removal.

Syntax
------

.. code-block:: lua

   skeleton:removeSelf()

Example
-------

.. code-block:: lua

   spineboy:removeSelf()
   print(spineboy.removeSelf)  -- nil: the skeleton is removed
   display.remove(spineboy)    -- does nothing on a removed object
