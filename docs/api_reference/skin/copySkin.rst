===================================
skin:copySkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`addSkin`, :doc:`../skeleton/createSkin`

Overview:
.........

Copies attachments from another skin into separate attachment objects. Unlike
:doc:`addSkin`, per-attachment color changes do not modify the original objects.
Meshes use Spine linked-mesh copying; texture resources and deformation/timeline
relationships are not fully independent.

This operation uses more memory than ``addSkin()``. See :doc:`/attachments-and-skins`.

Syntax:
--------

.. code-block:: lua

   local success = skin:copySkin(skinNameOrObject)
    
- ``skinNameOrObject`` *(required)*:
    ``string`` or ``Skin`` – Either the name of an existing skin or a Skin object.

Returns:
--------

``boolean`` – Returns ``true`` if successful, ``false`` if the skin was not found or invalid. A warning message starting with ``"WARNING: "`` is printed to stderr on failure.

Example:
--------

Create Independent Copy
........................

.. code-block:: lua

   -- Create a custom skin with independent attachments
   local variant = skeleton:createSkin("blueVariant")
   
   -- Deep copy the original skin
   variant:copySkin("original")
   
   -- Now we could modify the attachments without affecting "original"
   skeleton:setSkin(variant)

Template-Based Customization
.............................

.. code-block:: lua

   -- Create character variants from a template
   local function createVariant(name, baseSkin, additions)
       local custom = skeleton:createSkin(name)
       
       -- Copy template as starting point
       custom:copySkin(baseSkin)
       
       -- Add variant-specific parts
       for _, skinName in ipairs(additions) do
           custom:addSkin(skinName)
       end
       
       return custom
   end
   
   -- Create red and blue team variants
   local redTeam = createVariant("red", "soldier_base", {"red_armor", "red_badge"})
   local blueTeam = createVariant("blue", "soldier_base", {"blue_armor", "blue_badge"})

Notes:
--------

- Creates separate attachment objects, with linked-mesh semantics for meshes
- Uses more memory than addSkin
- Copies do not provide independent textures or all mesh/timeline data
- MeshAttachments use ``newLinkedMesh()`` for efficient copying
- Useful when you need to modify attachment properties per-character
- Returns ``false`` and prints a warning instead of throwing an error when the skin is not found
- Check the return value to handle cases where the skin might not exist

