local text = display.newText("Interactive Mix & Match", display.contentCenterX, display.screenOriginY + 30, native.systemFont, 28)
text:setFillColor(1, 0.8, 0.2)

-- Load the mix-and-match spine animation
local animationName = "mix-and-match"
local atlas = Spine.getAtlasData(animationName)
local skeletonData = Spine.getSkeletonData(animationName, atlas)

local parent = display.newGroup()
local skeleton = Spine.create(parent, skeletonData, display.contentCenterX, display.contentCenterY + 50)
skeleton:scale(.5, .5)

-- Play an idle animation
local animations = skeleton:getAnimations()
if #animations > 0 then
    skeleton:setAnimation(1, animations[1], true)
end

-- Get available skins and categorize them
local allSkins = skeleton:getSkins()
print("\n=== Available Skins ===")
for i, skinName in ipairs(allSkins) do
    print(i, skinName)
end

-- Filter out default skin
local skins = {}
for _, skinName in ipairs(allSkins) do
    if skinName ~= "default" then
        table.insert(skins, skinName)
    end
end

-- Organize skins by categories
local skinCategories = {}

-- Try to auto-categorize based on common naming patterns
for _, skinName in ipairs(skins) do
    local lower = string.lower(skinName)
    local category = "other"
    
    -- Categorize based on skin name patterns
    if string.find(lower, "full%-skins") then
        category = "Full Sets"
    elseif string.find(lower, "accessories") then
        category = "Accessories"
    elseif string.find(lower, "eyelids") then
        category = "Eyes"
    elseif string.find(lower, "eyes") then
        category = "Eyes"
    elseif string.find(lower, "clothes") then
        category = "Clothes"
    elseif string.find(lower, "legs") then
        category = "Legs"
    elseif string.find(lower, "pants") then
        category = "Legs"
    elseif string.find(lower, "hair") then
        category = "Hair"
    elseif string.find(lower, "skin") then
        category = "Skin"
    elseif string.find(lower, "body") then
        category = "Body"
    elseif string.find(lower, "nose") then
        category = "Face"
    elseif string.find(lower, "mouth") then
        category = "Face"
    end
    
    if not skinCategories[category] then
        skinCategories[category] = {}
    end
    table.insert(skinCategories[category], skinName)
end

-- Current selections for each category
local currentSelections = {}
for category, _ in pairs(skinCategories) do
    currentSelections[category] = 1 -- Start at first skin
end

-- Keep track of the current custom skin to prevent garbage collection
local currentCustomSkin = nil
local skinUpdateCounter = 0

-- Function to update the character with current selections
local function updateCharacter()
    -- Use a unique name each time to avoid conflicts
    skinUpdateCounter = skinUpdateCounter + 1
    local skinName = "interactive_custom_" .. skinUpdateCounter
    
    -- Create a new custom skin combining all current selections
    local customSkin = skeleton:createSkin(skinName)
    
    local partsUsed = {}
    for category, categorySkinsTable in pairs(skinCategories) do
        local index = currentSelections[category]
        local selectedSkin = categorySkinsTable[index]
        
        -- Use pcall to safely add skins and catch any errors
        local success, err = pcall(function()
            customSkin:addSkin(selectedSkin)
        end)
        
        if not success then
            print("Warning: Could not add skin '" .. selectedSkin .. "': " .. tostring(err))
        else
            table.insert(partsUsed, selectedSkin)
        end
    end
    
    -- Store reference to prevent garbage collection
    currentCustomSkin = customSkin
    
    -- Apply the custom skin
    local success, err = pcall(function()
        skeleton:setSkin(customSkin)
    end)
    
    if not success then
        print("Error applying skin: " .. tostring(err))
        -- Try to recover by applying a basic skin
        if #skins > 0 then
            skeleton:setSkin(skins[1])
        end
    else
        print("\n=== Current Combination ===")
        for i, part in ipairs(partsUsed) do
            print("  " .. part)
        end
    end
    
    -- Clean up old skins to prevent memory buildup
    -- Keep only the last few custom skins
    if skinUpdateCounter > 10 then
        collectgarbage("collect")
    end
end

-- UI Setup
local buttonY = display.contentHeight - 200
local buttonSpacing = 100
local buttonStartX = 60

local buttons = {}
local categoryLabels = {}

-- Create UI for each category
local categoryIndex = 0
local sortedCategories = {}
for category, _ in pairs(skinCategories) do
    table.insert(sortedCategories, category)
end
table.sort(sortedCategories)

for _, category in ipairs(sortedCategories) do
    local categorySkins = skinCategories[category]
    if #categorySkins > 0 then
        local x = buttonStartX + (categoryIndex % 4) * 180
        local y = buttonY + math.floor(categoryIndex / 4) * 70
        
        -- Category label
        local label = display.newText({
            text = category,
            x = x,
            y = y - 20,
            font = native.systemFontBold,
            fontSize = 14
        })
        label:setFillColor(0.3, 0.3, 0.3)
        table.insert(categoryLabels, label)
        
        -- Previous button
        local prevBtn = display.newCircle(x - 35, y, 15)
        prevBtn:setFillColor(0.3, 0.5, 0.8)
        local prevText = display.newText("<", x - 35, y, native.systemFontBold, 20)
        
        -- Current skin display
        local currentDisplay = display.newText({
            text = string.sub(categorySkins[1], 1, 10),
            x = x,
            y = y,
            font = native.systemFont,
            fontSize = 11,
            width = 60,
            align = "center"
        })
        currentDisplay:setFillColor(0, 0, 0)
        
        -- Next button
        local nextBtn = display.newCircle(x + 35, y, 15)
        nextBtn:setFillColor(0.3, 0.5, 0.8)
        local nextText = display.newText(">", x + 35, y, native.systemFontBold, 20)
        
        -- Store references
        buttons[category] = {
            prev = prevBtn,
            next = nextBtn,
            display = currentDisplay,
            prevText = prevText,
            nextText = nextText
        }
        
        -- Previous button handler
        prevBtn.category = category
        prevBtn:addEventListener("tap", function(event)
            local cat = event.target.category
            local categorySkins = skinCategories[cat]
            currentSelections[cat] = currentSelections[cat] - 1
            if currentSelections[cat] < 1 then
                currentSelections[cat] = #categorySkins
            end
            
            -- Update display
            local skinName = categorySkins[currentSelections[cat]]
            buttons[cat].display.text = string.sub(skinName, 1, 10)
            
            -- Small delay to prevent rapid clicking issues
            timer.performWithDelay(50, function()
                updateCharacter()
            end)
            return true
        end)
        
        -- Next button handler
        nextBtn.category = category
        nextBtn:addEventListener("tap", function(event)
            local cat = event.target.category
            local categorySkins = skinCategories[cat]
            currentSelections[cat] = currentSelections[cat] + 1
            if currentSelections[cat] > #categorySkins then
                currentSelections[cat] = 1
            end
            
            -- Update display
            local skinName = categorySkins[currentSelections[cat]]
            buttons[cat].display.text = string.sub(skinName, 1, 10)
            
            -- Small delay to prevent rapid clicking issues
            timer.performWithDelay(50, function()
                updateCharacter()
            end)
            return true
        end)
        
        categoryIndex = categoryIndex + 1
    end
end

-- Random button
local randomBtn = display.newRoundedRect(display.contentCenterX - 100, display.contentHeight - 50, 100, 40, 8)
randomBtn:setFillColor(0.8, 0.3, 0.3)
local randomText = display.newText("Random", randomBtn.x, randomBtn.y, native.systemFontBold, 16)

randomBtn:addEventListener("tap", function()
    -- Randomize all selections
    for category, categorySkins in pairs(skinCategories) do
        currentSelections[category] = math.random(1, #categorySkins)
        
        -- Update display
        if buttons[category] then
            local skinName = categorySkins[currentSelections[category]]
            buttons[category].display.text = string.sub(skinName, 1, 10)
        end
    end
    
    timer.performWithDelay(50, function()
        updateCharacter()
    end)
    return true
end)

-- Reset button
local resetBtn = display.newRoundedRect(display.contentCenterX + 100, display.contentHeight - 50, 100, 40, 8)
resetBtn:setFillColor(0.3, 0.6, 0.3)
local resetText = display.newText("Reset", resetBtn.x, resetBtn.y, native.systemFontBold, 16)

resetBtn:addEventListener("tap", function()
    -- Reset all selections to first item
    for category, categorySkins in pairs(skinCategories) do
        currentSelections[category] = 1
        
        -- Update display
        if buttons[category] then
            local skinName = categorySkins[1]
            buttons[category].display.text = string.sub(skinName, 1, 10)
        end
    end
    
    timer.performWithDelay(50, function()
        updateCharacter()
    end)
    return true
end)

-- Instructions
local instructions = display.newText({
    text = "Use < > buttons to mix & match!\nTap Random for a surprise!",
    x = display.contentCenterX,
    y = display.screenOriginY + 70,
    font = native.systemFont,
    fontSize = 14,
    align = "center"
})
instructions:setFillColor(0.5, 0.5, 0.5)

-- Initialize with first combination
updateCharacter()

print("\n=== Interactive Mix & Match Ready! ===")
print("Use the buttons to customize your character!")
print("Total categories:", #sortedCategories)

