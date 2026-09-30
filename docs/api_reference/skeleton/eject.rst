===================================
skeleton:eject()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`inject`

Overview:
.........

Removes a previously injected display object from the skeleton. After ejection, the object
is inserted into the stage group and its `listener` is no longer invoked.

Syntax:
--------

.. fragment: syntax line; object is a placeholder
.. code-block:: lua

   skeleton:eject(object)

Example:
--------

.. code-block:: lua

   local myHatObject = display.newRect(0, 0, 40, 20)

   -- Inject an object
   spineboy:inject(myHatObject, "head")

   -- Later, remove that object
   spineboy:eject(myHatObject)