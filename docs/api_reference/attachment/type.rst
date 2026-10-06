=======================================
attachment.type
=======================================

| **Type:** ``string`` (read-only)
| **Attachment types:** All

Overview
--------

The type of the attachment. This determines which properties and methods are available.

**Possible Values**

- ``"region"`` - A rectangular image/sprite (RegionAttachment)
- ``"mesh"`` - A deformable mesh (MeshAttachment)
- ``"boundingbox"`` - A collision polygon (BoundingBoxAttachment)
- ``"path"`` - A curved path for constraints (PathAttachment)
- ``"point"`` - A point with rotation (PointAttachment)
- ``"clipping"`` - A clipping mask (ClippingAttachment)
- ``"none"`` - No attachment (nil)

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("gun")
   local attachment = slot.attachment

   if attachment then
       if attachment.type == "region" then
           -- Can use x, y, rotation, scaleX, scaleY, etc.
           attachment.rotation = 45
       elseif attachment.type == "mesh" then
           -- Can use triangles, vertices, etc.
           print("Mesh has", #attachment.triangles, "triangle indices")
       elseif attachment.type == "point" then
           -- Can use x, y, rotation for spawn points
           print("Point at:", attachment.x, attachment.y)
       end
   end

