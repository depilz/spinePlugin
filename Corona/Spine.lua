local SpinePlugin = require('plugin.spine')

local Spine = {}
local atlases = {}
local skeletons = {}


function Spine.getAtlasData(name)
    if atlases[name] then return atlases[name] end

    local path = ("spines/%s/%s.atlas"):format(name, name)
    print(path)
    local absPath = system.pathForFile(path, system.ResourceDirectory)
    local atlas = SpinePlugin.loadAtlas(absPath)

    atlases[name] = atlas

    return atlas
end

function Spine.getSkeletonData(name, atlas)
    if skeletons[name] then return skeletons[name] end

    local path = ("spines/%s/%s.skel"):format(name, name)
    local absPath = system.pathForFile(path, system.ResourceDirectory)
    local skeleton = SpinePlugin.loadSkeletonData(absPath, atlas)

    skeletons[name] = skeleton

    return skeleton
end

function Spine.create(parent, skeletonData, x, y, listener)
    local skeleton = SpinePlugin.create(skeletonData, listener)

    skeleton.x, skeleton.y = x, y
    parent:insert(skeleton)

    return skeleton
end


return Spine
