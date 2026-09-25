=======================================
attachment.hullLength
=======================================

| **Type:** ``number`` (read-only)
| **Attachment Types:** mesh

The number of vertices that make up the mesh's convex hull boundary.

The convex hull vertices are stored at the beginning of the vertices array. 
These vertices define the outer boundary of the mesh before any internal 
vertices or deformation.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("cloth")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "mesh" then
       print("Hull vertices:", attachment.hullLength)
       print("Total vertices:", #attachment.vertices / 2)
       
       -- The first hullLength vertices form the outer boundary
       local worldVerts = attachment:computeWorldVertices(slot)
       
       -- Draw hull outline (first hullLength vertices)
       for i = 1, attachment.hullLength * 2, 2 do
           local x, y = worldVerts[i], worldVerts[i+1]
           print("Hull vertex:", x, y)
       end
   end

Notes
-----

- Measured in number of vertices, not array indices
- Hull vertices occupy the first ``hullLength`` positions in the vertices array
- Each vertex is 2 floats (x, y), so hull data is ``hullLength * 2`` array elements
- Used for mesh boundaries and weighted vertex calculations

See Also
--------

- :doc:`vertices` - The vertex positions array
- :doc:`triangles` - The triangle indices

