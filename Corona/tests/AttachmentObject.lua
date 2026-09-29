local text = display.newText("Testing Attachment Object!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

-- Load a spine animation with attachments
local atlas = Spine.getAtlasData("goblins")
local skeleton = Spine.getSkeletonData("goblins", atlas, 1)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
local animations = o:getAnimations()
o:setAnimation(1, animations[1], true)

-- Test the attachment object
timer.performWithDelay(1000, function()
    print("=== Testing Attachment Object ===")
    
    for i, slot in ipairs(o.slots) do
        -- Get attachment object
        local attachment = slot.attachment
        if attachment then
            print(string.format("Slot %d: %s", i, attachment.name))
            print(string.format("  - type: %s", attachment.type))
            
            -- Only region and mesh attachments have these properties
            if attachment.type == "region" or attachment.type == "mesh" then
                print(string.format("  - width: %s", tostring(attachment.width)))
                print(string.format("  - height: %s", tostring(attachment.height)))
                print(string.format("  - path: %s", tostring(attachment.path)))
                
                -- Test color access
                if attachment.color then
                    print(string.format("  - color: r=%s, g=%s, b=%s, a=%s", 
                        attachment.color.r, 
                        attachment.color.g, 
                        attachment.color.b, 
                        attachment.color.a))
                end
            end
        else
            print(string.format("Slot %d: no attachment", i))
        end
        print()
    end
    
    -- Test getAttachments and getSkinAttachments - they now return attachment objects
    print("=== Testing getAttachments (returns objects) ===")
    local allAttachments = o.slots[1]:getAttachments()
    for i, attachment in ipairs(allAttachments) do
        print(string.format("  Attachment %d: %s (type: %s)", i, attachment.name, attachment.type))
    end
    
    print("\n=== Testing getSkinAttachments (returns objects) ===")
    local skinAttachments = o.slots[1]:getSkinAttachments("goblin")
    for i, attachment in ipairs(skinAttachments) do
        print(string.format("  Attachment %d: %s (type: %s)", i, attachment.name, attachment.type))
    end

    -- Both optional forms must follow skin changes on the same slot objects.
    local previousSkin = o:getSkin()
    for _, skinName in ipairs(o:getSkins()) do
        o:setSkin(skinName)
        for _, slot in ipairs(o.slots) do
            local expected = slot:getSkinAttachments(skinName)
            local implicit = slot:getSkinAttachments()
            local explicitNil = slot:getSkinAttachments(nil)
            assert(type(implicit) == "table" and type(explicitNil) == "table")
            assert(#implicit == #expected and #explicitNil == #expected)
            for i, attachment in ipairs(expected) do
                assert(implicit[i].name == attachment.name)
                assert(explicitNil[i].name == attachment.name)
            end
            assert(not pcall(slot.getSkinAttachments, slot, "__missing_test_skin__"))
        end
    end
    if previousSkin then
        o:setSkin(previousSkin)
    end
end)

-- Test modifying attachment color
timer.performWithDelay(2000, function()
    print("=== Modifying Attachment Color ===")
    
    local slot = o.slots[1]
    local attachment = slot.attachment
    
    if attachment and (attachment.type == "region" or attachment.type == "mesh") then
        print("Before: r=" .. attachment.color.r)
        
        -- Modify color
        attachment.color = {r = 1, g = 0, b = 0, a = 1}
        
        print("After: r=" .. attachment.color.r)
        print("Attachment should now appear red")
    end
end)

-- Test setting attachment using object or string
timer.performWithDelay(4000, function()
    print("=== Testing Set Attachment ===")
    
    local slot = o.slots[1]
    local attachment = slot.attachment
    
    if attachment then
        print("Setting attachment using object...")
        -- You can set attachment using the object itself
        slot.attachment = attachment
        print("Attachment set using object!")
        
        -- Or using a string name
        slot.attachment = attachment.name
        print("Attachment set using string name!")
    end
end)
