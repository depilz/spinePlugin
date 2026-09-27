-- Test for slot:setAttachmentFromSkin() method
-- Demonstrates how to set slot attachments from specific skins

local spine = require "plugin.spine42"

-- Clean up any previous display objects
display.remove(display.getCurrentStage())

-- Create skeleton
local skeletonData = spine.loadSkeleton("spines/mix-and-match/mix-and-match", {})
local skeleton = spine.create(skeletonData)

skeleton.x = display.contentCenterX
skeleton.y = display.contentCenterY + 200
skeleton:setAnimation(0, "dance", true)

-- Get a slot
local headSlot = skeleton:findSlot("head")

print("\n=== Testing setAttachmentFromSkin ===")

-- Original attachment
print("Original attachment:", headSlot.attachment and headSlot.attachment.name or "none")

-- Wait a moment, then switch attachments using setAttachmentFromSkin
timer.performWithDelay(2000, function()
    print("\n--- Switching to 'full-skins/girl' skin 'head' attachment ---")
    
    -- Use the explicit method to set attachment from a specific skin
    headSlot:setAttachmentFromSkin("full-skins/girl", "head")
    
    print("New attachment:", headSlot.attachment and headSlot.attachment.name or "none")
end)

-- Switch to another skin's attachment
timer.performWithDelay(4000, function()
    print("\n--- Switching to 'full-skins/boy' skin 'head' attachment ---")
    
    headSlot:setAttachmentFromSkin("full-skins/boy", "head")
    
    print("New attachment:", headSlot.attachment and headSlot.attachment.name or "none")
end)

-- Try setting back to default
timer.performWithDelay(6000, function()
    print("\n--- Switching to 'default' skin 'head' attachment ---")
    
    headSlot:setAttachmentFromSkin("default", "head")
    
    print("New attachment:", headSlot.attachment and headSlot.attachment.name or "none")
end)

-- Test error handling - invalid skin
timer.performWithDelay(8000, function()
    print("\n--- Testing error handling: invalid skin ---")
    
    local success, err = pcall(function()
        headSlot:setAttachmentFromSkin("nonexistent-skin", "head")
    end)
    
    if not success then
        print("Error caught (as expected):", err)
    end
end)

-- Test error handling - invalid attachment
timer.performWithDelay(10000, function()
    print("\n--- Testing error handling: invalid attachment ---")
    
    local success, err = pcall(function()
        headSlot:setAttachmentFromSkin("default", "nonexistent-attachment")
    end)
    
    if not success then
        print("Error caught (as expected):", err)
    end
end)

-- Compare with the old property setter (uses current/default skin)
timer.performWithDelay(12000, function()
    print("\n--- Comparison: Using slot.attachment property (current/default skin) ---")
    
    -- First set a skin
    skeleton:setSkin("full-skins/girl")
    
    -- Now use the property setter - should get from current skin
    headSlot.attachment = "head"
    
    print("New attachment:", headSlot.attachment and headSlot.attachment.name or "none")
end)

print("\n--- Test will cycle through different skin attachments ---")
print("Watch the console for results and error handling demonstrations")

