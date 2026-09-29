=======================================
attachment.triangles
=======================================

| **Type:** ``table`` (read-only)
| **Attachment Types:** mesh

An array of vertex indices that define the triangles of the mesh.

The array contains indices into the vertices array, with every 3 indices
defining one triangle. The indices are in counter-clockwise winding order.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("cape")
   local attachment = slot.attachment

   if attachment and attachment.type == "mesh" then
       local triangles = attachment.triangles
       local numTriangles = #triangles / 3

       print("Mesh has", numTriangles, "triangles")

       -- Print first triangle's vertex indices
       if #triangles >= 3 then
           print("First triangle uses vertices:",
                 triangles[1], triangles[2], triangles[3])
       end

       -- Iterate all triangles
       for i = 1, #triangles, 3 do
           local v1, v2, v3 = triangles[i], triangles[i+1], triangles[i+2]
           print("Triangle:", v1, v2, v3)
       end
   end

Notes
-----

- Indices are 0-based (match the vertices array indexing)
- Each triangle uses 3 consecutive indices
- Triangles are in counter-clockwise winding order
- Read-only - cannot be modified at runtime
- Used internally for rendering and can be useful for custom collision detection

See Also
--------

- :doc:`vertices` - The vertex positions
- :doc:`computeWorldVertices` - Get world-space vertex positions
- :doc:`hullLength` - Number of vertices in the convex hull

