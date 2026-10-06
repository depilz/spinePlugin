===================================
attachment.a
===================================

| **Type:** ``number`` (read/write)
| **Attachment types:** region, mesh, point, path, boundingbox, clipping
| **See also:** :doc:`index`, :doc:`color`, :doc:`/naming`

Overview
--------

The **alpha** component of :doc:`color`, from 0.0 to 1.0. ``attachment.a`` reads and writes the same value as
``attachment.color.a``, one component at a time; the other components keep their value. Values are stored as
given, not clamped.

Every attachment type has a colour, but only region and mesh attachments are drawn, so only their colour shows.
Attachment objects are shared (see :doc:`index`): the write shows on every skeleton that uses the attachment.

Example
-------

.. code-block:: lua

   local attachment = spineboy:findSlot("gun").attachment
   attachment.a = 0.5
   print(attachment.a, attachment.color.a)  -- 0.5  0.5
