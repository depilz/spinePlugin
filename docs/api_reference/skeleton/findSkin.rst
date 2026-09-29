===================================
skeleton:findSkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`getSkin`, :doc:`setSkin`, :doc:`getSkins`, :doc:`../skin/index`

Overview:
.........

Returns the Skin object with the given name from the skeleton's data, or ``nil`` if there is none. The skin is not
applied; pass it to :doc:`setSkin` to apply it.

Syntax:
--------

.. code-block:: lua

   local skin = skeleton:findSkin(skinName)

- ``skinName`` *(required)*:
    ``string`` – The name of the skin to look up.

Returns:
--------

``Skin`` or ``nil`` – The skin with that name, or nil if the skeleton data has no such skin.

Example:
--------

.. code-block:: lua

   local skin = skeleton:findSkin("goblingirl")

   if skin then
       skeleton:setSkin(skin)
   end
