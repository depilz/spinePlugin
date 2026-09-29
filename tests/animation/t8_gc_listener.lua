-- T8: is a spine object (and its listener closure) collected when removeSelf() is never called on it, only on its
-- parent group (as Composer removes scene.view)? Solar2D finalizes it at the end of the frame, the next frame
-- disposes the skeleton, and nothing may keep the object, its SpineSkeleton userdata or the listener alive.
local spine = require("plugin.spine")
local S = __stub
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))

-- alive(withListener): 50 objects in a parent group that is removed; counts listener closures, spine objects and
-- SpineSkeleton userdata still alive after the next frame and a full GC
local function alive(withListener)
  local weak = setmetatable({}, {__mode = "k"})
  local parent = display.newGroup()
  for i = 1, 50 do
    local big = string.rep("x", 1e5) .. i -- captured upvalue, 100 KB each
    local fn = withListener and function(ev) return big end or nil
    local s = spine.create(data, fn)
    parent:insert(s)
    s:setAnimation(1, "walk", true)
    s:updateState(16)
    if fn then weak[fn] = "fn" end
    weak[s] = "obj"; weak[rawget(s, "_skeleton")] = "ud"
  end
  parent:removeSelf()
  parent = nil
  S.frame()
  S.gcfull()
  local n = { fn = 0, obj = 0, ud = 0 }
  for _, kind in pairs(weak) do n[kind] = n[kind] + 1 end
  print(("listener %s: alive after parent removal + GC: closures %d, objects %d, SpineSkeleton userdata %d of 50; Lua heap KB %d")
    :format(tostring(withListener), n.fn, n.obj, n.ud, math.floor(collectgarbage("count"))))
  return n
end
for _, withListener in ipairs({true, false}) do
  local n = alive(withListener)
  C.expect(n.fn == 0 and n.obj == 0 and n.ud == 0,
    "spine objects removed with their parent are not collected (listener " .. tostring(withListener) .. ")")
end
C.done()
