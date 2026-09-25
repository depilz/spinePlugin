=======================================
attachment:computeWorldVertices()
=======================================

| **Returns:** ``table`` (array of numbers)
| **Attachment Types:** region, mesh, path, boundingbox, clipping

Computes the world-space positions of the attachment's vertices.

This method transforms the attachment's local vertices through bone 
transformations (position, rotation, scale) to produce final world-space 
coordinates. It also applies any active deformations from the slot.

Syntax
------

.. code-block:: lua

   local worldVertices = attachment:computeWorldVertices(slot)

Parameters
----------

- **slot** (``userdata``) - The slot containing this attachment

Returns
-------

A table of numbers representing vertex positions in world space, formatted as:

``{x1, y1, x2, y2, x3, y3, ...}``

Each pair of values represents one vertex's x and y coordinates.

Example
-------

**Region attachment (4 vertices):**

.. code-block:: lua

   local slot = skeleton:findSlot("weapon")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "region" then
       local verts = attachment:computeWorldVertices(slot)
       
       -- Region has 4 corners = 8 values
       -- Bottom-right, Bottom-left, Upper-left, Upper-right
       local brX, brY = verts[1], verts[2]
       local blX, blY = verts[3], verts[4]
       local ulX, ulY = verts[5], verts[6]
       local urX, urY = verts[7], verts[8]
       
       print("Bottom-right corner:", brX, brY)
   end

**Bounding box collision:**

.. code-block:: lua

   local function pointInPolygon(px, py, vertices)
       -- Standard point-in-polygon test
       local inside = false
       local j = #vertices - 1
       
       for i = 1, #vertices, 2 do
           local vix, viy = vertices[i], vertices[i+1]
           local vjx, vjy = vertices[j], vertices[j+1]
           
           if ((viy > py) ~= (vjy > py)) and 
              (px < (vjx - vix) * (py - viy) / (vjy - viy) + vix) then
               inside = not inside
           end
           
           j = i
       end
       
       return inside
   end
   
   local hitboxSlot = skeleton:findSlot("hitbox")
   local hitbox = hitboxSlot.attachment
   
   if hitbox and hitbox.type == "boundingbox" then
       local worldVerts = hitbox:computeWorldVertices(hitboxSlot)
       
       -- Check if mouse click is inside hitbox
       if pointInPolygon(mouseX, mouseY, worldVerts) then
           print("Hit!")
       end
   end

**Mesh rendering:**

.. code-block:: lua

   local meshSlot = skeleton:findSlot("cloth")
   local mesh = meshSlot.attachment
   
   if mesh and mesh.type == "mesh" then
       -- Get world vertex positions
       local worldVerts = mesh:computeWorldVertices(meshSlot)
       local triangles = mesh.triangles
       
       -- Draw each triangle
       for i = 1, #triangles, 3 do
           local i1, i2, i3 = triangles[i], triangles[i+1], triangles[i+2]
           
           -- Vertex indices are 0-based, but Lua arrays are 1-based
           -- The vertices are x,y pairs
           local x1, y1 = worldVerts[i1*2+1], worldVerts[i1*2+2]
           local x2, y2 = worldVerts[i2*2+1], worldVerts[i2*2+2]
           local x3, y3 = worldVerts[i3*2+1], worldVerts[i3*2+2]
           
           -- Draw triangle with these coordinates
           drawTriangle(x1, y1, x2, y2, x3, y3)
       end
   end

**Path visualization:**

.. code-block:: lua

   local pathSlot = skeleton:findSlot("rope")
   local path = pathSlot.attachment
   
   if path and path.type == "path" then
       local worldVerts = path:computeWorldVertices(pathSlot)
       
       -- Draw path outline
       for i = 1, #worldVerts - 2, 2 do
           local x1, y1 = worldVerts[i], worldVerts[i+1]
           local x2, y2 = worldVerts[i+2], worldVerts[i+3]
           
           drawLine(x1, y1, x2, y2)
       end
       
       -- Close the path if needed
       if path.closed and #worldVerts >= 4 then
           local x1, y1 = worldVerts[#worldVerts-1], worldVerts[#worldVerts]
           local x2, y2 = worldVerts[1], worldVerts[2]
           drawLine(x1, y1, x2, y2)
       end
   end

Notes
-----

- Vertex positions are in world space (screen coordinates)
- Includes all bone transformations (position, rotation, scale, shear)
- Applies slot deformations if present
- Handles both single-bone and multi-bone weighted vertices
- The returned array is always a multiple of 2 (x, y pairs)
- Calling this every frame can be expensive for complex meshes - cache when possible

Return Value by Type
--------------------

- **region**: 8 values (4 corners: BR, BL, UL, UR)
- **mesh**: Variable, based on mesh complexity (``worldVerticesLength`` values)
- **boundingbox**: Variable, based on polygon vertices
- **path**: Variable, based on path control points
- **clipping**: Variable, based on clipping polygon

See Also
--------

- :doc:`vertices` - The local vertex data
- :doc:`bones` - Bone weighting information
- :doc:`worldVerticesLength` - Expected number of values returned
- :doc:`triangles` - Triangle indices (mesh only)

