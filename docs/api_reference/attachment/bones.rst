=======================================
attachment.bones
=======================================

| **Type:** ``table`` (read-only)
| **Attachment Types:** mesh, path, boundingbox, clipping

An array of bone indices for weighted vertex attachments.

If this array is empty, the attachment uses unweighted vertices (attached to a 
single bone). If it contains data, the attachment's vertices are influenced by 
multiple bones with individual weights.

The format is complex and primarily used internally. For practical vertex 
positions, use :doc:`computeWorldVertices` instead.

Example
-------

.. code-block:: lua

   local slot = skeleton:findSlot("cloth")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "mesh" then
       local bones = attachment.bones
       
       if #bones == 0 then
           print("Mesh is attached to single bone:", slot.bone.name)
       else
           print("Mesh uses weighted vertices with", #bones, "bone references")
           print("Use computeWorldVertices() for actual positions")
       end
       
       -- Get world vertices regardless of weighting
       local worldVerts = attachment:computeWorldVertices(slot)
   end

**Checking attachment type:**

.. code-block:: lua

   local function isWeighted(attachment)
       if attachment.bones then
           return #attachment.bones > 0
       end
       return false
   end
   
   local attachment = slot.attachment
   if attachment and attachment.type == "mesh" then
       if isWeighted(attachment) then
           print("Uses multiple bones for deformation")
       else
           print("Attached to single bone")
       end
   end

Notes
-----

- Empty array (``#bones == 0``) means unweighted (single bone)
- Non-empty array means vertices are influenced by multiple bones
- Complex internal format - not meant for direct manipulation
- Read-only - cannot be modified at runtime
- Weighted vertices enable more natural deformation across bones

See Also
--------

- :doc:`vertices` - The vertex coordinate data
- :doc:`worldVerticesLength` - Expected number of world coordinates
- :doc:`computeWorldVertices` - Get final transformed positions

