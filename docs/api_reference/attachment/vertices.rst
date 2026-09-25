=======================================
attachment.vertices
=======================================

| **Type:** ``table`` (read-only)
| **Attachment Types:** mesh, path, boundingbox, clipping

An array of vertex data for vertex-based attachments.

The format depends on whether the attachment uses weighted vertices (influenced 
by multiple bones) or unweighted vertices (single bone).

**Unweighted vertices:** Array of x, y coordinate pairs: ``{x1, y1, x2, y2, ...}``

**Weighted vertices:** More complex format with bone indices and weights. 
Use :doc:`bones` to determine if vertices are weighted.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("hitbox")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "boundingbox" then
       local vertices = attachment.vertices
       local bones = attachment.bones
       
       if #bones == 0 then
           -- Unweighted - simple x,y pairs
           print("Unweighted vertices:")
           for i = 1, #vertices, 2 do
               local x, y = vertices[i], vertices[i+1]
               print("Vertex:", x, y)
           end
       else
           -- Weighted - complex format
           print("Weighted vertices (use computeWorldVertices)")
       end
       
       -- Get actual world positions regardless of format
       local worldVerts = attachment:computeWorldVertices(slot)
       for i = 1, #worldVerts, 2 do
           print("World vertex:", worldVerts[i], worldVerts[i+1])
       end
   end

**Mesh vertices:**

.. code-block:: lua

   local meshSlot = skeleton:findSlot("cape")  
   local mesh = meshSlot.attachment
   
   if mesh and mesh.type == "mesh" then
       print("Mesh has", #mesh.vertices, "vertex coordinates")
       print("That's", #mesh.vertices / 2, "vertices")
       
       -- For collision or physics, use world vertices
       local worldVerts = mesh:computeWorldVertices(meshSlot)
   end

Notes
-----

- Read-only - cannot be modified at runtime
- Coordinates are in the bone's local space
- For world-space positions, use :doc:`computeWorldVertices`
- Deformations are applied separately via slot deform data
- Weighted vertices have a complex format - always use ``computeWorldVertices`` for actual positions

See Also
--------

- :doc:`bones` - Bone indices for weighted vertices
- :doc:`worldVerticesLength` - Expected number of world vertex coordinates
- :doc:`computeWorldVertices` - Get transformed world-space positions
- :doc:`triangles` - Triangle indices (mesh only)

