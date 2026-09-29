===================================
skeleton.physics
===================================

| **Type:** ``userdata`` | ``nil``
| **See also:** :doc:`../index`

Overview:
..........
----------

The **physics** object exposes physics constraints on a Spine skeleton if they exist. 
All physics constraints in the skeleton share the same properties (wind, inertia, etc.), 
so changing a property on this object affects **all** constraints.

If the skeleton has no physics constraints, skeleton.physics will be nil.

Properties
----------
----------

.. toctree::
   :maxdepth: 1

   isActive
   mix
   xVelocity
   yVelocity
   gravity
   inertia
   wind
   strength
   damping
   massInverse

Methods
-------
-------

.. toctree::
   :maxdepth: 1

   translate
   rotate