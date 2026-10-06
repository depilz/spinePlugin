===================================
trackEntry
===================================

| **Type:** ``userdata``
| **See also:** :doc:`../index`, :doc:`../tracks`

Overview
--------

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

.. only:: spine43

   ``holdPrevious`` was removed in Spine 4.3: reading or writing it raises
   ``SpineTrackEntry: property 'holdPrevious' was removed in Spine 4.3; use additive or mixInterpolation``
   (after the :doc:`isValid` error on an entry that is no longer valid). Nothing replaces it: the 4.3 runtime
   always holds the previous entry during a mix, as ``holdPrevious = true`` did on the 4.2 line, and neither
   ``additive`` nor ``mixInterpolation`` (listed below) does that (see :doc:`/migration`).


Properties
----------

Common
~~~~~~

.. toctree::
   :maxdepth: 1

   trackIndex <trackIndex>
   animation <animation>
   timeScale <timeScale>
   loop <loop>
   delay <delay>
   reverse <reverse>
   isComplete <isComplete>
   isValid <isValid>
   trackTime <trackTime>
   trackEnd <trackEnd>
   onComplete <onComplete>

Advanced
~~~~~~~~

.. toctree::
   :maxdepth: 1

   alpha <alpha>
   additive <additive>
   holdPrevious <holdPrevious>
   animationTime <animationTime>
   animationStart <animationStart>
   animationEnd <animationEnd>
   animationLast <animationLast>
   shortestRotation <shortestRotation>
   eventThreshold <eventThreshold>
   mixTime <mixTime>
   mixDuration <mixDuration>
   mixInterpolation <mixInterpolation>
   trackComplete <trackComplete>
   next <next>
   mixingFrom <mixingFrom>
   mixingTo <mixingTo>
   mixAttachmentThreshold <mixAttachmentThreshold>
   alphaAttachmentThreshold <alphaAttachmentThreshold>
   mixDrawOrderThreshold <mixDrawOrderThreshold>

Methods
-------

.. toctree::
   :maxdepth: 1

   setMixDuration() <setMixDuration>
