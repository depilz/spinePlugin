local SpinePlugin = require('plugin.spine43')

local Spine = {}
local atlases = {}
local skeletonsData = {}

local skeletons = {}
local sampleAliases = {
    sack = {
        folder = "7-anticipation",
        atlas = "7-anticipation",
    },
}

local function getSample(name)
    local baseName = name:gsub("%-pma$", "")
    local sample = sampleAliases[baseName] or {}

    return {
        folder = sample.folder or baseName,
        atlas = sample.atlas or baseName,
        skeleton = sample.skeleton or baseName,
        pma = name ~= baseName,
    }
end

local function findExport(folder, filenames)
    for _, filename in ipairs(filenames) do
        local path = ("spines/%s/export/%s"):format(folder, filename)
        if system.pathForFile(path, system.ResourceDirectory) then
            return path
        end
    end

    error(("No Spine export found in spines/%s/export"):format(folder), 3)
end

function _G.printpath(...)
    local s = "✧ 🚏 "
    for i = 1, #arg do
        if type(arg[i]) == "string" then
            for c in arg[i]:gmatch(".") do
                s = s .. c .. "‎" -- take care, invisible characters here!
            end
        else
            s = s .. tostring(arg[i])
        end
        s = s .. "\t"
    end
    print(s)
end


function Spine.getAtlasData(name)
    if atlases[name] then return atlases[name] end

    local sample = getSample(name)
    local suffix = sample.pma and "-pma" or ""
    local path = findExport(sample.folder, {
        sample.atlas .. suffix .. ".atlas",
    })
    local atlas = SpinePlugin.loadAtlas(path)
    atlases[name] = atlas

    return atlas
end

function Spine.getSkeletonData(name, atlas, scale)
    if skeletonsData[name] then return skeletonsData[name] end

    local sample = getSample(name)
    local path = findExport(sample.folder, {
        sample.skeleton .. ".skel",
        sample.skeleton .. "-pro.skel",
        sample.skeleton .. "-ess.skel",
    })

    local data = SpinePlugin.loadSkeletonData(path, atlas, scale)

    skeletonsData[name] = data

    return data
end

function Spine.create(parent, skeletonData, x, y, listener)
    local skeleton = SpinePlugin.create(skeletonData, listener)

    skeleton.x, skeleton.y = x, y
    parent:insert(skeleton)

    skeletons[#skeletons + 1] = skeleton
    if skeleton.removeSelf then
        skeleton:draw()
    end

    return skeleton
end

local remove = table.remove
function Spine.remove(skeleton)
    for i = 1, #skeletons do
        if skeletons[i] == skeleton then
            remove(skeletons, i)
            break
        end
    end

    skeleton:removeSelf()
end

local time = system.getTimer()
Runtime:addEventListener("enterFrame", function()
    local dt = system.getTimer() - time
    time = time + dt

    for i, skeleton in ipairs(skeletons) do
        if skeleton.removeSelf and skeleton.parent then
            skeleton:updateState(dt)
            if skeleton.removeSelf then
                skeleton:draw()
            end
        end
    end
end)


return Spine
