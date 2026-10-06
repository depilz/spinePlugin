===================================
skeleton.physics
===================================

| **Type:** ``userdata`` | ``nil``
| **See also:** :doc:`../index`

Overview
--------

The **physics** object exposes physics constraints on a Spine skeleton if they exist.
All physics constraints in the skeleton share the same properties (wind, inertia, etc.),
so changing a property on this object affects **all** constraints.

If the skeleton has no physics constraints, skeleton.physics will be nil.

Properties
----------

.. toctree::
   :maxdepth: 1

   isActive <isActive>
   mix <mix>
   xVelocity <xVelocity>
   yVelocity <yVelocity>
   gravity <gravity>
   inertia <inertia>
   wind <wind>
   strength <strength>
   damping <damping>
   massInverse <massInverse>

Methods
-------

.. toctree::
   :maxdepth: 1

   translate() <translate>
   rotate() <rotate>
