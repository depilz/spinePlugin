======
Naming
======

The skeleton display object speaks Solar2D: it is a display group, so it has ``x``, ``y``, ``xScale``, ``alpha``
and every other display object key. Every Spine object (bone, slot, attachment, skin, track entry, constraints)
speaks Spine's own vocabulary. A page documents each concept under its **canonical** name, the one this rule
picks. Where the other vocabulary's name also works, it is an **alias**: it reads and writes the same value as the
canonical name, on both plugin lines, with no warning. Aliases are permanent; code that uses them keeps working.
An alias has a short page of its own that links the canonical page, except the IK constraint lookups: their names
differ only in letter case, so both names share one page.

.. list-table::
   :header-rows: 1
   :widths: 14 22 18 20 26

   * - Concept
     - Canonical
     - Alias
     - Where
     - Note
   * - Local scale
     - ``scaleX``, ``scaleY``
     - ``xScale``, ``yScale``
     - :doc:`bone <api_reference/skeleton/bone/scaleX>`, region
       :doc:`attachment <api_reference/attachment/scaleX>`
     - The skeleton object is a display group: its own scale is ``xScale``/``yScale``, and it has no ``scaleX``.
   * - Colour
     - ``color`` (a table ``{r, g, b, a}``) and ``r``, ``g``, ``b``, ``a``
     - ``slot.alpha`` (for ``slot.a``)
     - :doc:`slot <api_reference/skeleton/slot/color>`, :doc:`skin <api_reference/skin/color>`,
       :doc:`skeleton.fill <api_reference/skeleton/fill/color>`,
       :doc:`attachment <api_reference/attachment/color>`
     - :doc:`trackEntry.alpha <api_reference/skeleton/trackEntry/alpha>` is the mix alpha, not a colour, and the
       inject event's ``alpha`` is a display object value: neither has an ``a``.
   * - Track index
     - ``trackIndex``
     - ``entry.index``
     - :doc:`trackEntry <api_reference/skeleton/trackEntry/trackIndex>`,
       :doc:`listener event <api_reference/spine/event>`
     - 1-based; read-only on the track entry.
   * - Looping
     - ``loop``
     - ``event.looping``
     - :doc:`trackEntry <api_reference/skeleton/trackEntry/loop>`,
       :doc:`listener event <api_reference/spine/event>`
     - The event carries it on every phase except ``"event"``.
   * - IK constraint lookup
     - ``getIkConstraint()``, ``getIkConstraintNames()``
     - ``getIKConstraint()``, ``getIKConstraintNames()``
     - :doc:`skeleton <api_reference/skeleton/getIKConstraint>`
     - Spine's ``IkConstraint`` casing, like the :doc:`api_reference/skeleton/ikConstraints` property.
   * - Name
     - ``name``
     - ``skin:getName()``
     - every Spine object
     - :doc:`api_reference/skin/getName` returns :doc:`api_reference/skin/name`.
   * - Inject event
     - ``x``, ``y``, ``rotation``, ``xScale``, ``yScale``, ``alpha``, ``isVisible``
     - none
     - :doc:`api_reference/skeleton/injectionEvent`
     - Display object names on purpose: they are the values you copy to the injected display object. Its
       ``alpha`` is the animated Spine slot colour, not :doc:`slot.a <api_reference/skeleton/slot/a>`.
   * - Bone world matrix
     - ``a``, ``b``, ``c``, ``d``
     - none
     - :doc:`bone <api_reference/skeleton/bone/a>`
     - Spine's matrix notation; on a bone these are not colour components.
   * - Collections
     - properties ``slots``, ``bones``, ``ikConstraints``, ``tracks``, ``fill``; methods
       ``getSlotNames()``, ``getIkConstraintNames()``, ``getSkin()``
     - none
     - :doc:`skeleton <api_reference/skeleton/index>`
     - A property returns objects; a ``get…Names()`` method returns names. ``getSkin()`` has no property form.
   * - Spine's own names
     - ``physics.xVelocity``, ``physics.yVelocity``; ``isActive``; ``setFillColor()``
     - none
     - :doc:`api_reference/skeleton/physics/index`, :doc:`api_reference/skeleton/isActive`,
       :doc:`api_reference/skeleton/setFillColor`
     - ``xVelocity``/``yVelocity`` are Spine's names. ``skeleton.isActive`` means a track is playing; a
       constraint's ``isActive`` is Spine's own flag. ``setFillColor(r, g, b, a)`` writes ``fill.r/g/b/a``, but a
       one-argument ``setFillColor(v)`` also sets ``a = 1``, while ``fill.r = v`` leaves ``a`` as it was.
