=======================================
attachment.hullLength
=======================================

| **Type:** ``number`` (read-only)
| **Attachment Types:** mesh

The size of the mesh's hull: the outer boundary drawn in the Spine editor.

The hull vertices come first, so the hull is the start of the array
:doc:`computeWorldVertices` returns.

.. only:: spine42

   On this line ``hullLength`` counts **vertices**: the hull is the first ``hullLength * 2`` numbers of
   the world vertices array.

.. only:: spine43

   On this line ``hullLength`` counts **numbers** (x and y of each vertex): the hull is the first
   ``hullLength`` numbers of the world vertices array, ``hullLength / 2`` vertices.

Example
-------

.. only:: spine42

   .. code-block:: lua

      local slot = skeleton:findSlot("cape")
      local attachment = slot.attachment

      if attachment and attachment.type == "mesh" then
          print("Hull vertices:", attachment.hullLength)
          print("Total vertices:", attachment.worldVerticesLength / 2)

          -- The hull is the start of the world vertices
          local worldVerts = attachment:computeWorldVertices(slot)
          for i = 1, attachment.hullLength * 2, 2 do
              print("Hull vertex:", worldVerts[i], worldVerts[i+1])
          end
      end

.. only:: spine43

   .. code-block:: lua

      local slot = skeleton:findSlot("cape")
      local attachment = slot.attachment

      if attachment and attachment.type == "mesh" then
          print("Hull vertices:", attachment.hullLength / 2)
          print("Total vertices:", attachment.worldVerticesLength / 2)

          -- The hull is the start of the world vertices
          local worldVerts = attachment:computeWorldVertices(slot)
          for i = 1, attachment.hullLength, 2 do
              print("Hull vertex:", worldVerts[i], worldVerts[i+1])
          end
      end

Notes
-----

- The Spine 4.2 runtime stores the hull as a vertex count and the Spine 4.3 runtime as a count of numbers,
  so the same export reads 24 on the 4.2 line and 48 on the 4.3 line

See Also
--------

- :doc:`vertices` - The vertex positions array
- :doc:`triangles` - The triangle indices

