===================================
attachment
===================================

| **Type:** ``userdata``
| **See also:** :doc:`../skeleton/slot/attachment`, :doc:`../skin/getAttachment`


Overview:
..........

An **Attachment** object represents visual or functional elements attached to a skeleton's slots. 
Attachments can be images (regions), deformable meshes, collision boxes, paths for constraints, 
points for spawning effects, or clipping masks.

The attachment type determines which properties and methods are available. All attachments share 
common properties like ``name`` and ``type``, while type-specific properties are only available 
on the appropriate attachment types.

Attachment objects are **shared**: skins that contain the same attachment (for example after
:doc:`../skin/addSkin` or :doc:`../skin/setAttachment`) and every skeleton instance of the same skeleton data
use the same object, so a property write shows everywhere. Use :doc:`copy` for a separate object. Two
Attachment objects compare equal with ``==`` when they wrap the same attachment.

Writing a property the attachment's type does not have raises
``SpineAttachment: unknown property '<key>' on a <type> attachment``.

Attachment Types
................

- **region** - A rectangular image/sprite (RegionAttachment)
- **mesh** - A deformable mesh with vertices and triangles (MeshAttachment)  
- **boundingbox** - A polygon used for collision detection (BoundingBoxAttachment)
- **path** - A curved path used for path constraints (PathAttachment)
- **point** - A single point with rotation, useful for spawn points (PointAttachment)
- **clipping** - A polygon that clips rendering (ClippingAttachment)

Common Properties
-----------------

Available on all attachment types:

.. toctree::
   :maxdepth: 1

   name
   type

Visual Properties
-----------------

Color and appearance:

.. toctree::
   :maxdepth: 1

   color

RegionAttachment Properties
----------------------------

Available when ``type == "region"``:

.. toctree::
   :maxdepth: 1

   x
   y
   rotation
   scaleX
   scaleY
   width
   height
   path

MeshAttachment Properties
--------------------------

Available when ``type == "mesh"``:

.. toctree::
   :maxdepth: 1

   width
   height
   path
   triangles
   hullLength
   vertices
   bones
   worldVerticesLength

PointAttachment Properties
---------------------------

Available when ``type == "point"``:

.. toctree::
   :maxdepth: 1

   x
   y
   rotation

PathAttachment Properties
--------------------------

Available when ``type == "path"``:

.. toctree::
   :maxdepth: 1

   closed
   constantSpeed
   lengths
   vertices
   bones
   worldVerticesLength

VertexAttachment Properties
----------------------------

Available when ``type`` is "boundingbox", "path", "mesh", or "clipping":

.. toctree::
   :maxdepth: 1

   vertices
   bones
   worldVerticesLength

Methods
-------

.. toctree::
   :maxdepth: 1

   computeWorldVertices
   copy

Example Usage
-------------

**Working with Region Attachments:**

.. code-block:: lua

   local slot = skeleton:findSlot("head")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "region" then
       print("Attachment name:", attachment.name)
       print("Position:", attachment.x, attachment.y)
       print("Rotation:", attachment.rotation)
       print("Scale:", attachment.scaleX, attachment.scaleY)
       
       -- Modify the attachment
       attachment.rotation = 45
       attachment.scaleX = 1.5
       attachment.color = {r=1, g=0.5, b=0.5, a=1}
   end

**Working with Point Attachments:**

.. code-block:: lua

   local pointSlot = skeleton:findSlot("bulletSpawn")
   local point = pointSlot.attachment
   
   if point and point.type == "point" then
       -- Use for spawning effects at the point location
       print("Spawn point:", point.x, point.y, point.rotation)
   end

**Computing World Vertices for Collision:**

.. code-block:: lua

   local slot = skeleton:findSlot("hitbox")
   local attachment = slot.attachment
   
   if attachment and attachment.type == "boundingbox" then
       -- Get world-space vertex positions
       local worldVerts = attachment:computeWorldVertices(slot)
       
       -- worldVerts is an array: {x1, y1, x2, y2, x3, y3, ...}
       -- Use for collision detection
       for i = 1, #worldVerts, 2 do
           local x, y = worldVerts[i], worldVerts[i+1]
           print("Vertex:", x, y)
       end
   end

**Working with Mesh Attachments:**

.. code-block:: lua

   local meshSlot = skeleton:findSlot("cape")
   local mesh = meshSlot.attachment
   
   if mesh and mesh.type == "mesh" then
       print("Mesh has", #mesh.triangles / 3, "triangles")
       print("Hull length:", mesh.hullLength)
       
       -- Get mesh vertices in world space
       local worldVerts = mesh:computeWorldVertices(meshSlot)
   end

**Path Attachments:**

.. code-block:: lua

   local pathSlot = skeleton:findSlot("ropePath")
   local path = pathSlot.attachment
   
   if path and path.type == "path" then
       print("Path is closed:", path.closed)
       print("Constant speed:", path.constantSpeed)
       print("Curve lengths:", table.concat(path.lengths, ", "))
   end

