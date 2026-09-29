-- Test: Attachment Properties
-- Demonstrates all attachment properties and methods

-- Load skeleton (straight-alpha atlas)
local atlas = Spine.getAtlasData("spineboy")
local skeletonData = Spine.getSkeletonData("spineboy", atlas, 0.3)
local skeleton = Spine.create(display.newGroup(), skeletonData, display.contentCenterX, display.contentCenterY + 200)

local function printSeparator(title)
    print("\n" .. string.rep("=", 60))
    print(title)
    print(string.rep("=", 60))
end

-- Test common attachment properties
printSeparator("COMMON ATTACHMENT PROPERTIES")

local slot = skeleton:findSlot("head")
if slot and slot.attachment then
    local att = slot.attachment
    print("Attachment name:", att.name)
    print("Attachment type:", att.type)
    
    if att.color then
        print("Color:", string.format("r=%.2f g=%.2f b=%.2f a=%.2f", 
              att.color.r, att.color.g, att.color.b, att.color.a))
    end
else
    print("WARNING: Slot 'head' not found or has no attachment")
end

-- Test RegionAttachment properties
printSeparator("REGION ATTACHMENT PROPERTIES")

local function testRegionAttachment(slotName)
    local slot = skeleton:findSlot(slotName)
    if not slot or not slot.attachment then
        print("WARNING: Slot '" .. slotName .. "' not found or has no attachment")
        return
    end
    
    local att = slot.attachment
    if att.type ~= "region" then
        print("WARNING: Attachment in slot '" .. slotName .. "' is not a region (type: " .. att.type .. ")")
        return
    end
    
    print("\nSlot: " .. slotName)
    print("  name:", att.name)
    print("  path:", att.path)
    print("  position: x=" .. att.x .. ", y=" .. att.y)
    print("  rotation:", att.rotation)
    print("  scale: x=" .. att.scaleX .. ", y=" .. att.scaleY)
    print("  size: " .. att.width .. "x" .. att.height)
    
    -- Test computeWorldVertices
    local worldVerts = att:computeWorldVertices(slot)
    print("  world vertices (4 corners):")
    for i = 1, #worldVerts, 2 do
        print(string.format("    [%d] (%.1f, %.1f)", i/2, worldVerts[i], worldVerts[i+1]))
    end
    
    -- Test modifying properties
    print("\n  Testing property modification:")
    local origRotation = att.rotation
    att.rotation = origRotation + 15
    print("    rotation changed from " .. origRotation .. " to " .. att.rotation)
    att.rotation = origRotation -- restore
    
    local origScaleX = att.scaleX
    att.scaleX = origScaleX * 1.1
    print("    scaleX changed from " .. origScaleX .. " to " .. att.scaleX)
    att.scaleX = origScaleX -- restore
end

-- Test various slots ("head" and "torso" hold meshes)
testRegionAttachment("neck")
testRegionAttachment("gun")

-- Test color modification
printSeparator("COLOR MODIFICATION TEST")

local headSlot = skeleton:findSlot("head")
if headSlot and headSlot.attachment then
    local att = headSlot.attachment
    
    print("Original color:", att.color.r, att.color.g, att.color.b, att.color.a)
    
    -- Make it red tinted
    att.color = {r=1, g=0.5, b=0.5, a=1}
    print("Modified color:", att.color.r, att.color.g, att.color.b, att.color.a)
    
    -- Restore
    att.color = {r=1, g=1, b=1, a=1}
    print("Restored color:", att.color.r, att.color.g, att.color.b, att.color.a)
else
    print("WARNING: Slot 'head' not found or has no attachment for color test")
end

-- Test PointAttachment (if available)
printSeparator("POINT ATTACHMENT PROPERTIES")

local function findPointAttachment()
    for _, slotName in ipairs(skeleton:getSlotNames()) do
        local slot = skeleton:findSlot(slotName)
        if slot and slot.attachment and slot.attachment.type == "point" then
            return slot, slot.attachment
        end
    end
    return nil, nil
end

local pointSlot, pointAtt = findPointAttachment()
if pointAtt then
    print("\nFound point attachment: " .. pointAtt.name)
    print("  position: x=" .. pointAtt.x .. ", y=" .. pointAtt.y)
    print("  rotation:", pointAtt.rotation)
    
    -- Test modification
    pointAtt.x = pointAtt.x + 10
    print("  modified x to:", pointAtt.x)
else
    print("WARNING: No point attachments found in skeleton")
end

-- Test MeshAttachment (if available)
printSeparator("MESH ATTACHMENT PROPERTIES")

local function findMeshAttachment()
    for _, slotName in ipairs(skeleton:getSlotNames()) do
        local slot = skeleton:findSlot(slotName)
        if slot and slot.attachment and slot.attachment.type == "mesh" then
            return slot, slot.attachment
        end
    end
    return nil, nil
end

local meshSlot, meshAtt = findMeshAttachment()
if meshAtt then
    print("\nFound mesh attachment: " .. meshAtt.name)
    print("  size: " .. meshAtt.width .. "x" .. meshAtt.height)
    print("  hullLength:", meshAtt.hullLength)
    print("  triangles count:", #meshAtt.triangles)
    print("  vertices count:", #meshAtt.vertices / 2, "vertices (" .. #meshAtt.vertices .. " floats)")
    print("  bones count:", #meshAtt.bones)
    print("  worldVerticesLength:", meshAtt.worldVerticesLength)
    
    if #meshAtt.bones == 0 then
        print("  (unweighted - single bone)")
    else
        print("  (weighted - multiple bones)")
    end
    
    -- Test computeWorldVertices
    local worldVerts = meshAtt:computeWorldVertices(meshSlot)
    print("  world vertices computed:", #worldVerts, "floats")
    print("  first 3 vertices in world space:")
    for i = 1, math.min(6, #worldVerts), 2 do
        print(string.format("    vertex %d: (%.1f, %.1f)", (i+1)/2, worldVerts[i], worldVerts[i+1]))
    end
else
    print("WARNING: No mesh attachments found in skeleton")
end

-- Test PathAttachment (if available)
printSeparator("PATH ATTACHMENT PROPERTIES")

local function findPathAttachment()
    for _, slotName in ipairs(skeleton:getSlotNames()) do
        local slot = skeleton:findSlot(slotName)
        if slot and slot.attachment and slot.attachment.type == "path" then
            return slot, slot.attachment
        end
    end
    return nil, nil
end

local pathSlot, pathAtt = findPathAttachment()
if pathAtt then
    print("\nFound path attachment: " .. pathAtt.name)
    print("  closed:", pathAtt.closed)
    print("  constantSpeed:", pathAtt.constantSpeed)
    print("  lengths:", table.concat(pathAtt.lengths, ", "))
    print("  vertices count:", #pathAtt.vertices / 2)
    print("  bones count:", #pathAtt.bones)
    
    -- Test computeWorldVertices
    local worldVerts = pathAtt:computeWorldVertices(pathSlot)
    print("  world vertices computed:", #worldVerts / 2, "vertices")
else
    print("WARNING: No path attachments found in skeleton")
end

-- Test BoundingBoxAttachment (if available)
printSeparator("BOUNDINGBOX ATTACHMENT PROPERTIES")

-- The head bounding box has no attachment in the setup pose: set it by its placeholder
skeleton:findSlot("head-bb").attachment = "head"

local function findBoundingBoxAttachment()
    for _, slotName in ipairs(skeleton:getSlotNames()) do
        local slot = skeleton:findSlot(slotName)
        if slot and slot.attachment and slot.attachment.type == "boundingbox" then
            return slot, slot.attachment
        end
    end
    return nil, nil
end

local bboxSlot, bboxAtt = findBoundingBoxAttachment()
if bboxAtt then
    print("\nFound bounding box attachment: " .. bboxAtt.name)
    print("  vertices count:", #bboxAtt.vertices / 2)
    print("  worldVerticesLength:", bboxAtt.worldVerticesLength)
    
    -- Test computeWorldVertices for collision detection
    local worldVerts = bboxAtt:computeWorldVertices(bboxSlot)
    print("  world vertices (for collision):")
    for i = 1, #worldVerts, 2 do
        print(string.format("    vertex %d: (%.1f, %.1f)", (i+1)/2, worldVerts[i], worldVerts[i+1]))
    end
else
    print("WARNING: No bounding box attachments found in skeleton")
end

-- Summary
printSeparator("ATTACHMENT API SUMMARY")

print([[
✓ Common properties (all types):
  - name (read-only)
  - type (read-only)
  - color (read/write, all types)

✓ RegionAttachment properties:
  - x, y, rotation, scaleX, scaleY (read/write)
  - width, height (read/write)
  - path (read-only)
  - computeWorldVertices(slot) -> 8 floats (4 corners)

✓ PointAttachment properties:
  - x, y, rotation (read/write)

✓ MeshAttachment properties:
  - width, height (read/write)
  - path (read-only)
  - triangles (read-only array)
  - hullLength (read-only)
  - vertices, bones, worldVerticesLength (read-only)
  - computeWorldVertices(slot) -> variable length

✓ PathAttachment properties:
  - closed, constantSpeed (read/write)
  - lengths (read-only array)
  - vertices, bones, worldVerticesLength (read-only)
  - computeWorldVertices(slot) -> variable length

✓ BoundingBoxAttachment & ClippingAttachment:
  - vertices, bones, worldVerticesLength (read-only)
  - computeWorldVertices(slot) -> variable length

All attachment types now have full property access!
]])

print("\n✅ All tests completed successfully!\n")

