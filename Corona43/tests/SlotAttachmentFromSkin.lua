-- Test for slot:setAttachmentFromSkin() method
-- Demonstrates how to set slot attachments from specific skins

-- Create skeleton
local atlas = Spine.getAtlasData("mix-and-match")
local skeletonData = Spine.getSkeletonData("mix-and-match", atlas, 0.5)
local skeleton = Spine.create(display.newGroup(), skeletonData, display.contentCenterX, display.contentCenterY + 200)

skeleton:setSkin("full-skins/girl")
skeleton:setAnimation(1, "dance", true)

-- Get a slot
local hatSlot = skeleton:findSlot("hat")

print("\n=== Testing setAttachmentFromSkin ===")

-- Original attachment
print("Original attachment:", hatSlot.attachment and hatSlot.attachment.name or "none")

-- Wait a moment, then switch attachments using setAttachmentFromSkin
timer.performWithDelay(2000, function()
    print("\n--- Switching to 'full-skins/boy' skin 'hat' attachment ---")

    -- Use the explicit method to set attachment from a specific skin
    hatSlot:setAttachmentFromSkin("full-skins/boy", "hat")

    print("New attachment:", hatSlot.attachment and hatSlot.attachment.name or "none")
end)

-- Switch to another skin's attachment
timer.performWithDelay(4000, function()
    print("\n--- Switching to 'accessories/hat-pointy-blue-yellow' skin 'hat' attachment ---")

    hatSlot:setAttachmentFromSkin("accessories/hat-pointy-blue-yellow", "hat")

    print("New attachment:", hatSlot.attachment and hatSlot.attachment.name or "none")
end)

-- And a third skin's
timer.performWithDelay(6000, function()
    print("\n--- Switching to 'accessories/hat-red-yellow' skin 'hat' attachment ---")

    hatSlot:setAttachmentFromSkin("accessories/hat-red-yellow", "hat")

    print("New attachment:", hatSlot.attachment and hatSlot.attachment.name or "none")
end)

-- Test error handling - invalid skin
timer.performWithDelay(8000, function()
    print("\n--- Testing error handling: invalid skin ---")

    local success, err = pcall(function()
        hatSlot:setAttachmentFromSkin("nonexistent-skin", "hat")
    end)

    if not success then
        print("Error caught (as expected):", err)
    end
end)

-- Test error handling - a skin without the attachment
timer.performWithDelay(10000, function()
    print("\n--- Testing error handling: skin without the attachment ---")

    local success, err = pcall(function()
        hatSlot:setAttachmentFromSkin("skin-base", "hat")
    end)

    if not success then
        print("Error caught (as expected):", err)
    end
end)

-- Compare with the old property setter (uses current/default skin)
timer.performWithDelay(12000, function()
    print("\n--- Comparison: Using slot.attachment property (current/default skin) ---")

    -- First set a skin
    skeleton:setSkin("full-skins/boy")

    -- Now use the property setter - should get from current skin
    hatSlot.attachment = "hat"

    print("New attachment:", hatSlot.attachment and hatSlot.attachment.name or "none")
end)

print("\n--- Test will cycle through different skin attachments ---")
print("Watch the console for results and error handling demonstrations")
