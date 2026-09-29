-- The stub's frame emulation: removal orphans, the end of the frame finalizes, then the next frame's enterFrame runs.
local S = __stub
local order = {}
local parent = display.newGroup()
local g = display.newGroup(); parent:insert(g)
g:addEventListener("finalize", function() order[#order + 1] = "finalize" end)
g:removeSelf()
assert(not S.isRemoved(g) and getmetatable(g) ~= nil and g.parent == nil, "removal finalized synchronously")
assert(#S.children(parent) == 0, "a removed object stays in its parent")
assert(pcall(display.remove, g), "a second removal in the same frame raises")
local rescued = display.newGroup(); rescued:removeSelf(); parent:insert(rescued)
local oneShot
oneShot = function(e)
  order[#order + 1] = "enterFrame " .. e.frame
  assert(Runtime:removeEventListener("enterFrame", oneShot) == true, "a successful removal does not return true")
end
local tableListener = { enterFrame = function(self, e) order[#order + 1] = "table " .. e.frame end }
Runtime:addEventListener("enterFrame", tableListener)
assert(Runtime:hasEventListener("enterFrame", tableListener), "a table listener alone is not seen")
Runtime:removeEventListener("enterFrame", tableListener)
-- Solar2D's Runtime keeps a duplicate and removes the first match: only armDisposeHook's hasEventListener check
-- keeps the plugin's hook single (below)
assert(Runtime:addEventListener("enterFrame", oneShot) and Runtime:addEventListener("enterFrame", oneShot),
  "a duplicate listener was refused")
assert(Runtime:removeEventListener("enterFrame", oneShot) and Runtime:hasEventListener("enterFrame", oneShot)
  and #rawget(Runtime, "_functionListeners").enterFrame == 1, "remove did not drop exactly the first match")
Runtime:addEventListener("enterFrame", tableListener)
assert(Runtime:hasEventListener("enterFrame", oneShot) and rawget(Runtime, "_functionListeners").enterFrame[1] == oneShot)
assert(S.frame())
assert(S.isRemoved(g) and getmetatable(g) == nil, "the end of the frame did not finalize the orphan")
assert(not S.isRemoved(rescued) and rescued.parent == parent, "a re-inserted orphan was finalized")
assert(not Runtime:hasEventListener("enterFrame", oneShot), "the one-shot listener is still registered")
assert(S.frame())
print(table.concat(order, ", "))
assert(table.concat(order, ",") == "finalize,enterFrame 1,table 1,table 2", "frame order")

-- two skeletons finalized in one frame arm the plugin's dispose hook once
local spine = require("plugin.spine")
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
spine.create(data):removeSelf(); spine.create(data):removeSelf()
S.endFrame()
local hooks = rawget(Runtime, "_functionListeners").enterFrame
assert(hooks and #hooks == 1, "the dispose hook was armed " .. (hooks and #hooks or 0) .. " times")
assert(S.frame())
assert(rawget(Runtime, "_functionListeners").enterFrame == nil, "the dispose hook did not remove itself")
