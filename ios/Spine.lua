local SpinePlugin = require('plugin.spine')

local Spine = {}
local atlases = {}
local skeletons = {}


function Spine.getAtlasData(atlasPath)
    if atlases[atlasPath] then return atlases[atlasPath] end

    local absPath = system.pathForFile(atlasPath .. ".atlas", system.ResourceDirectory)
    local atlas = SpinePlugin.loadAtlas(absPath)

    atlases[atlasPath] = atlas

    return atlas
end

function Spine.getSkeletonData(skelPath, atlas)
    if skeletons[skelPath] then return skeletons[skelPath] end

    local absPath = system.pathForFile(skelPath .. ".skel", system.ResourceDirectory)
    local skeleton = SpinePlugin.loadSkeletonData(absPath, atlas)

    skeletons[skelPath] = skeleton

    return skeleton
end

function Spine.create(parent, skeletonData, x, y, listener)
    local skeleton = SpinePlugin.create(skeletonData, listener)
    
    skeleton.x, skeleton.y = x, y
    parent:insert(skeleton)

    return skeleton
end


return Spine
