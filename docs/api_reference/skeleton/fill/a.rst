===================================
skeleton.fill.a
===================================

| **Type:** ``number``
| **See also:** :doc:`../fill`, :doc:`color`, :doc:`../setFillColor`, :doc:`/naming`

Overview
--------

The **alpha** component of the skeleton's fill colour (0–1). The fill colour multiplies the colour of every
attachment the skeleton draws. ``skeleton.fill.a`` reads and writes the same value as
``skeleton.fill.color.a``, and as the matching argument of :doc:`../setFillColor`, one component at a time: the
other components keep their value.

Example
-------

.. code-block:: lua

   spineboy.fill.a = 0.5
   print(spineboy.fill.a, spineboy.fill.color.a)  -- 0.5  0.5
