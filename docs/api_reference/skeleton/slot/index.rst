===================================
slot
===================================

| **Type:** ``userdata``
| **See also:** :doc:`../slots`, :doc:`../index`


Overview:
..........
----------

A **Slot** object represents the attachment slot for a bone in a Spine skeleton. It holds color 
tints (RGBA), a current attachment, and a reference to its owning bone. 
Each slot can be manipulated independently to change visuals (e.g., attachments)
or adjust colors.

Below is a list of the Slot’s properties. Most can be **read or written**, except for the slot
name and bone reference.

Properties:
--------
--------

.. toctree::
   :maxdepth: 1

   name
   bone
   attachment
   r
   g
   b
   alpha
   color
   getAttachments
   getSkinAttachments