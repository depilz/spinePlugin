===================================
skeleton:eject()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`inject`

Overview:
.........
--------

Removes any previously injected display object from the skeleton. After ejection, the slot
is inserted into the stage group and the `listener` is no longer invoked.

Syntax:
--------
--------

.. code-block:: lua

   skeleton:eject(object)

Example:
--------
--------

.. code-block:: lua

   -- Inject an object
   hero:inject(myHatObject, "head", onUpdateHat)
   ...
   -- Later, remove that object
   hero:eject(myHatObject)