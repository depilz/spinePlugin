local SpinePlugin = require('plugin.spine')

local Spine = {}
local atlases = {}
local skeletonsData = {}

local skeletons = {}


function Spine.getAtlasData(name)
    if atlases[name] then return atlases[name] end

    local path = ("spines/%s/%s.atlas"):format(name, name)
    local absPath = system.pathForFile(path, system.ResourceDirectory)
    local atlas = SpinePlugin.loadAtlas(absPath)

    atlases[name] = atlas

    return atlas
end

function Spine.getSkeletonData(name, atlas)
    if skeletonsData[name] then return skeletonsData[name] end

    local path = ("spines/%s/%s.skel"):format(name, name)
    local absPath = system.pathForFile(path, system.ResourceDirectory)
    local data = SpinePlugin.loadSkeletonData(absPath, atlas)

    skeletonsData[name] = data

    return data
end

function Spine.create(parent, skeletonData, x, y, listener)
    local skeleton = SpinePlugin.create(skeletonData, listener)

    skeleton.x, skeleton.y = x, y
    parent:insert(skeleton)

    skeletons[#skeletons + 1] = skeleton
    skeleton:draw()

    return skeleton
end

local time = system.getTimer()
Runtime:addEventListener("enterFrame", function()
    local dt = system.getTimer() - time
    time = time + dt

    for i, skeleton in ipairs(skeletons) do
        if skeleton.isActive and skeleton.parent then
            skeleton:updateState(dt)
            skeleton:draw()
        end
    end
end)


return Spine
