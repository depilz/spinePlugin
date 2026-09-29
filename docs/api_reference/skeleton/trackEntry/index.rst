===================================
trackEntry
===================================

| **Type:** ``userdata``
| **See also:** :doc:`../index`, :doc:`../tracks`

Overview:
..........

A **trackEntry** object represents an individual animation track within a Spine skeleton.
It manages the playback state of a specific animation, including its timing, looping behavior,
mixing parameters, and more.

``entry.index`` is an alias of :doc:`trackIndex`: it reads the same 1-based track index (see :doc:`/naming`).

Two ``trackEntry`` objects compare equal with ``==`` when they stand for the same entry, for example
``skeleton:getTrackEntry(1) == skeleton.tracks[1]``. An entry that was returned to the pool and reused is a new
entry: an object you kept for the old one is not equal to it. Comparing never raises.

Reading a key the entry does not have returns ``nil``. Writing to it raises
``SpineTrackEntry: unknown property '<key>'``, and writing to a read-only property (``trackIndex``, ``index``, ``animation``,
``animationTime``, ``isComplete``, ``isValid``, ``trackComplete``, ``next``, ``mixingFrom``, ``mixingTo``) raises
``SpineTrackEntry: property '<key>' is read-only``. On an entry that is no longer valid, the
:doc:`isValid` error comes first.


Properties
----------

**Common**

.. toctree::
   :maxdepth: 1

   trackIndex
   animation
   timeScale
   loop
   delay
   reverse
   isComplete
   isValid
   trackTime
   trackEnd
   onComplete

**Advanced**

.. toctree::
   :maxdepth: 1

   alpha
   holdPrevious
   animationTime
   animationStart
   animationEnd
   animationLast
   shortestRotation
   eventThreshold
   mixTime
   mixDuration
   trackComplete
   next
   mixingFrom
   mixingTo
   mixAttachmentThreshold
   alphaAttachmentThreshold
   mixDrawOrderThreshold

Methods
-------

.. toctree::
   :maxdepth: 1

   setMixDuration
