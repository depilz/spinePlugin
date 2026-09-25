=======================================
attachment.worldVerticesLength
=======================================

| **Type:** ``number`` (read-only)
| **Attachment Types:** mesh, path, boundingbox, clipping

The expected number of float values in the world vertices array.

This is always ``numberOfVertices * 2`` (since each vertex has x and y coordinates).

Use this to pre-allocate arrays or validate vertex data when working with 
world vertex positions.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("hitbox")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "boundingbox" then
       local length = attachment.worldVerticesLength
       local numVertices = length / 2
       
       print("Bounding box has", numVertices, "vertices")
       print("World vertices array will have", length, "floats")
       
       -- Get the world vertices
       local worldVerts = attachment:computeWorldVertices(slot)
       assert(#worldVerts == length, "Vertex count mismatch")
   end

**Pre-allocating for custom rendering:**

.. code-block:: lua

   local mesh = meshSlot.attachment
   if mesh and mesh.type == "mesh" then
       -- Know how many coordinates to expect
       local expectedCount = mesh.worldVerticesLength
       
       local worldVerts = mesh:computeWorldVertices(meshSlot)
       
       -- Process vertices knowing the count
       for i = 1, expectedCount, 2 do
           local x, y = worldVerts[i], worldVerts[i+1]
           -- Use for rendering or collision
       end
   end

Notes
-----

- Always an even number (pairs of x, y coordinates)
- Does not change during runtime
- Matches the length of the array returned by ``computeWorldVertices()``
- Useful for validation and pre-allocation

See Also
--------

- :doc:`vertices` - The local vertex data
- :doc:`computeWorldVertices` - Get world-space positions

