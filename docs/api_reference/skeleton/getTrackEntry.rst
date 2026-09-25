===================================
skeleton:getTrackEntry()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`trackEntry/index`

Overview:
.........

Returns the currently active :doc:`trackEntry/index` for a track.
Returns ``nil`` if the track has no active animation.

Syntax:
--------

.. code-block:: lua

   local trackEntryOrNil = skeleton:getTrackEntry(trackIndex)

- ``trackIndex`` *(required)*:
    ``number`` – 1-based track index.

Return value:
-------------

- ``trackEntry or nil`` – Active entry for the track, or ``nil``.

Example:
--------

.. code-block:: lua

   local entry = hero:getTrackEntry(1)
   if entry then
       print("Current animation:", entry.animation)
   end
