===================================
ikConstraint
===================================

An **IKConstraint** object defines inverse-kinematics relationships for one or more bones in 
a Spine skeleton. This typically allows you to control bones by a target bone, making complex 
motion (such as arms or legs following a point) much simpler.

Below is a list of all properties on an IKConstraint. Most are **read/write**, except for the
constraint’s name and list of bones. Each property affects **only** this particular constraint.

Contents
--------

.. toctree::
   :maxdepth: 1

   name
   bones
   isActive
   mix
   stretch
   softness
   bendDirection
   compress
   order
   target