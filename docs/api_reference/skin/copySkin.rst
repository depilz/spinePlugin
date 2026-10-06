===================================
skin:copySkin()
===================================

| **Type:** ``function``
| **See also:** :doc:`index`, :doc:`addSkin`, :doc:`../skeleton/createSkin`

Overview
--------

Copies attachments from another skin into separate attachment objects. Unlike
:doc:`addSkin`, per-attachment color changes do not modify the original objects.
Meshes use Spine linked-mesh copying; texture resources and deformation/timeline
relationships are not fully independent.

This operation uses more memory than ``addSkin()``. See :doc:`/attachments-and-skins`.

Syntax
------

.. fragment: syntax line; skin and skinNameOrObject are placeholders
.. code-block:: lua

   skin:copySkin(skinNameOrObject)

Parameters
----------

- ``skinNameOrObject`` *(required)*:
    ``string`` or ``Skin`` – Either the name of an existing skin or a Skin object of the same skeleton data.
    A name finds only the skeleton data's skins, so a skin made with
    ``skeleton:createSkin()`` must be passed as the Skin object.

Return value
------------

``Skin`` – The skin itself, so calls can be chained.

Raises a Lua error, and changes nothing, when this skin is a data skin (read-only), or when the
other skin is not found, has the wrong type or belongs to different skeleton data.

Example
-------

The examples use the mix-and-match example skeleton, whose skins each dress part of the character.

Create Independent Copy
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Create a custom skin with independent attachments
   local variant = girl:createSkin("blueVariant")

   -- Deep copy the original skin
   variant:copySkin("full-skins/girl")

   -- Now we could modify the attachments without affecting "full-skins/girl"
   girl:setSkin(variant)

Template-Based Customization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: lua

   local girl = spine.create(spine.loadSkeletonData("assets/characters/mix-and-match.json",
                                                    spine.loadAtlas("assets/characters/mix-and-match.atlas")))

   -- Create character variants from a template
   local function createVariant(name, baseSkin, additions)
       local custom = girl:createSkin(name)

       -- Copy template as starting point
       custom:copySkin(baseSkin)

       -- Add variant-specific parts
       for _, skinName in ipairs(additions) do
           custom:addSkin(skinName)
       end

       return custom
   end

   -- Create red and blue team variants
   local redTeam = createVariant("red", "full-skins/boy", {"accessories/cape-red"})
   local blueTeam = createVariant("blue", "full-skins/boy", {"accessories/cape-blue"})
   girl:setSkin(redTeam)

Notes
-----

- Creates separate attachment objects, with linked-mesh semantics for meshes
- Uses more memory than addSkin
- Copies do not provide independent textures or all mesh/timeline data
- MeshAttachments use ``newLinkedMesh()`` for efficient copying
- Useful when you need to modify attachment properties per-character
- Raises on a data skin: data skins are read-only (see :doc:`index`)
- Raises when the skin is not found; use :doc:`../skeleton/findSkin` to check first
- To copy a single attachment, use :doc:`../attachment/copy`
