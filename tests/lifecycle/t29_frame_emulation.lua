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
  assert(Runtime:removeEventListener("enterFrame", oneShot) == nil)
end
local tableListener = { enterFrame = function(self, e) order[#order + 1] = "table " .. e.frame end }
Runtime:addEventListener("enterFrame", tableListener)
assert(Runtime:hasEventListener("enterFrame", tableListener), "a table listener alone is not seen")
Runtime:removeEventListener("enterFrame", tableListener)
assert(Runtime:addEventListener("enterFrame", oneShot) and not Runtime:addEventListener("enterFrame", oneShot),
  "a listener registers once")
Runtime:addEventListener("enterFrame", tableListener)
assert(Runtime:hasEventListener("enterFrame", oneShot) and rawget(Runtime, "_functionListeners").enterFrame[1] == oneShot)
S.frame()
assert(S.isRemoved(g) and getmetatable(g) == nil, "the end of the frame did not finalize the orphan")
assert(not S.isRemoved(rescued) and rescued.parent == parent, "a re-inserted orphan was finalized")
assert(not Runtime:hasEventListener("enterFrame", oneShot), "the one-shot listener is still registered")
S.frame()
print(table.concat(order, ", "))
assert(table.concat(order, ",") == "finalize,enterFrame 1,table 1,table 2", "frame order")
