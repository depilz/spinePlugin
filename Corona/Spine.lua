SpinePlugin = require('plugin.spine')

local Spine = {}
local atlases = {}
local skeletonsData = {}

local skeletons = {}

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

    local folder = name:gsub("-pma", "")

    local path = ("spines/%s/%s.atlas"):format(folder, name)
    local atlas = SpinePlugin.loadAtlas(path)
    atlases[name] = atlas

    return atlas
end

function Spine.getSkeletonData(name, atlas, scale)
    if skeletonsData[name] then return skeletonsData[name] end

    local path = ("spines/%s/%s.skel"):format(name, name)

    local data = SpinePlugin.loadSkeletonData(path, atlas, scale)

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
        if skeleton.isActive and skeleton.parent then
            skeleton:updateState(dt)
            skeleton:draw()
        end
    end
end)


return Spine
