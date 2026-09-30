=======================================
attachment:computeWorldVertices()
=======================================

| **Returns:** ``table`` (array of numbers)
| **Attachment Types:** region, mesh, path, boundingbox, clipping

Computes the positions of the attachment's vertices in skeleton space.

This method transforms the attachment's local vertices through bone
transformations (position, rotation, scale) to produce the coordinates Spine calls "world"
coordinates: skeleton space, the skeleton display object's own local coordinates (Y grows downward).
It also applies any active deformations from the slot. Use ``skeleton:localToContent(x, y)`` for
content (screen) coordinates.

Syntax
------

.. fragment: syntax line; attachment and slot are placeholders
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

   local slot = skeleton:findSlot("gun")
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

**Bounding box collision** (spineboy's ``head-bb`` slot holds a bounding box, empty in the setup pose):

.. code-block:: lua

   local spineboy = spine.create(spine.loadSkeletonData("assets/characters/spineboy.json",
                                                        spine.loadAtlas("assets/characters/spineboy.atlas")))

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

   spineboy:setAttachment("head-bb", "head")
   local hitboxSlot = spineboy:findSlot("head-bb")
   local hitbox = hitboxSlot.attachment

   if hitbox and hitbox.type == "boundingbox" then
       -- Check if a touch is inside the hitbox: bring the touch into skeleton space first
       spineboy:addEventListener("touch", function(event)
           local x, y = spineboy:contentToLocal(event.x, event.y)
           if pointInPolygon(x, y, hitbox:computeWorldVertices(hitboxSlot)) then
               print("Hit!")
           end
       end)
   end

**Mesh rendering:**

.. code-block:: lua

   local meshSlot = skeleton:findSlot("torso")
   local mesh = meshSlot.attachment

   if mesh and mesh.type == "mesh" then
       -- Get world vertex positions
       local worldVerts = mesh:computeWorldVertices(meshSlot)
       local triangles = mesh.triangles
       local area = 0

       -- Visit each triangle
       for i = 1, #triangles, 3 do
           local i1, i2, i3 = triangles[i], triangles[i+1], triangles[i+2]

           -- Vertex indices are 0-based, but Lua arrays are 1-based
           -- The vertices are x,y pairs
           local x1, y1 = worldVerts[i1*2+1], worldVerts[i1*2+2]
           local x2, y2 = worldVerts[i2*2+1], worldVerts[i2*2+2]
           local x3, y3 = worldVerts[i3*2+1], worldVerts[i3*2+2]

           -- Use the triangle, here to sum the area the mesh covers
           area = area + math.abs((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)) / 2
       end
       print("Torso covers", area, "square units")
   end

**Path outline** (the control points, including the Bezier handles):

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   local pathSlot = girl:findSlot("arm-front-path")
   local path = pathSlot.attachment

   if path and path.type == "path" then
       local worldVerts = path:computeWorldVertices(pathSlot)
       local length = 0

       -- Walk the outline point to point
       for i = 1, #worldVerts - 2, 2 do
           local x1, y1 = worldVerts[i], worldVerts[i+1]
           local x2, y2 = worldVerts[i+2], worldVerts[i+3]
           length = length + math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
       end

       -- Close the outline if the path is closed
       if path.closed and #worldVerts >= 4 then
           local x1, y1 = worldVerts[#worldVerts-1], worldVerts[#worldVerts]
           local x2, y2 = worldVerts[1], worldVerts[2]
           length = length + math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
       end
       print("Outline length:", length)
   end

Notes
-----

- Vertex positions are in skeleton space: the skeleton display object's local coordinates, Y downward
  (``skeleton:localToContent(x, y)`` converts one to content coordinates)
- Includes all bone transformations (position, rotation, scale, shear) as of the last world transform update
  (:doc:`../skeleton/updateState`); for an attachment on a bone the current skin does not activate the
  positions are not meaningful
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

