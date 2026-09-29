-- Minimal Solar2D display/graphics/system emulation for the lifecycle harness.
io.stdout:setvbuf("no")
-- Mirrors the engine behaviours that matter for object lifetime, per Solar2D sources:
--  * removeSelf/remove only move the object to the Orphanage (librtt/Rtt_LuaProxyVTable.cpp PushAndRemove); the
--    orphans are finalized at the end of the frame (~RuntimeGuard -> Display::Collect, librtt/Rtt_Runtime.cpp,
--    librtt/Display/Rtt_Display.cpp). S.frame() ends the frame, then starts the next one with Runtime "enterFrame".
--    This timing is emulated, not measured in the engine.
--  * finalizing a group makes every descendant unreachable: children first, then the group
--    (librtt/Display/Rtt_GroupObject.cpp MakeUnreachable), and each object runs FinalizeSelf:
--    dispatch "finalize" if it has a listener, then RestoreTable: t._proxy=nil, t._class=nil,
--    setmetatable(t, nil)  (librtt/Display/Rtt_DisplayObject.cpp:291-313, librtt/Rtt_LuaProxy.cpp:724-751)
--  * property access through the display metatable on a table with no _proxy raises in the
--    Simulator (LuaProxy::GetProxy -> luaL_checkudata, Rtt_LuaProxy.cpp:314-339).
--  * display objects dispatch through Solar2D's EventDispatcher (platform/resources/init.lua:74-160 and :162-273,
--    DisplayObject :461-478): function listeners, then table listeners, each over a clone of its list.
local S = { groupsCreated = 0, meshesCreated = 0, finalized = 0, texturesCreated = 0, texturesReleased = 0,
            liveTextures = {}, meshUpdates = 0, log = false }
_G.__stub = S

local DOMT = {}          -- shared "display object" metatable (like Solar2D's proxy metatable)
local methods = {}
local orphanage = { __children = {} }   -- engine-owned group of removed objects, collected by S.endFrame()

local function isGroup(t) return rawget(t, "__children") ~= nil end

DOMT.__index = function(t, k)
  if rawget(t, "_proxy") == nil then
    error("bad argument #-1 to '?' (luaproxy expected, got nil)", 2)
  end
  if k == "parent" then local p = rawget(t, "__parent"); if p ~= orphanage then return p end return nil end
  if k == "stage" then return display.getCurrentStage() end
  if k == "numChildren" and isGroup(t) then return #rawget(t, "__children") end
  if type(k) == "number" and isGroup(t) then return rawget(t, "__children")[k] end
  local m = methods[k]
  if m then return m end
  return rawget(t, "__props")[k]
end
DOMT.__newindex = function(t, k, v)
  if rawget(t, "_proxy") == nil then
    error("bad argument #-1 to '?' (luaproxy expected, got nil)", 2)
  end
  if k == "fill" and type(v) == "table" then
    local c = {} for kk, vv in pairs(v) do c[kk] = vv end
    v = c
  end
  rawget(t, "__props")[k] = v
end

local stage

local function newDisplayObject(kind)
  local t = { _proxy = newproxy(false), __props = {}, __kind = kind }
  setmetatable(t, DOMT)
  return t
end

local function detach(child)
  local p = rawget(child, "__parent")
  if p then
    local ch = rawget(p, "__children")
    for i = #ch, 1, -1 do if rawequal(ch[i], child) then table.remove(ch, i) end end
    rawset(child, "__parent", nil)
  end
end

local function finalizeSelf(t)
  -- DisplayObject::FinalizeSelf -> DispatchEventWithTarget: one event, dispatched through the object's dispatchEvent
  if methods.respondsToEvent(t, "finalize") then t:dispatchEvent({ name = "finalize", target = t }) end
  S.finalized = S.finalized + 1
  rawset(t, "_proxy", nil)
  rawset(t, "_class", nil)
  -- hierarchy is native in Solar2D: drop the stub's Lua-side links so they don't pin anything
  rawset(t, "__parent", nil); rawset(t, "__children", nil); rawset(t, "__props", nil)
  setmetatable(t, nil)
end

local function makeUnreachable(t)
  if isGroup(t) then
    local ch = rawget(t, "__children")
    for i = #ch, 1, -1 do makeUnreachable(ch[i]) end
  end
  finalizeSelf(t)
end

local function orphan(t) methods.insert(orphanage, t) end

function methods.removeSelf(self)
  if rawget(self, "_proxy") == nil then error("removeSelf on removed object", 2) end
  orphan(self)
end
function methods.insert(self, index, child)
  if child == nil then child, index = index, nil end
  assert(type(child) == "table", "insert: child expected")
  detach(child)
  local ch = rawget(self, "__children")
  if type(index) == "number" then
    if index < 1 then index = 1 end
    if index > #ch + 1 then index = #ch + 1 end
    table.insert(ch, index, child)
  else
    ch[#ch + 1] = child
  end
  rawset(child, "__parent", self)
end
function methods.remove(self, child)
  if type(child) == "number" then child = rawget(self, "__children")[child] end
  if child then orphan(child) end
end
-- Solar2D's EventDispatcher (platform/resources/init.lua); the listener lists are raw fields of the object, read with
-- rawget/rawset where init.lua reads them through __index.
-- Its add/removeEventListener reach their helpers through self (EventDispatcher:addEventListener/removeEventListener,
-- DisplayObject:addEventListener/removeEventListener), so an object that hides the helpers raises there.
local LISTENER_INDEX = { ["table"] = "_tableListeners", ["function"] = "_functionListeners" }
local DISPATCH_ORDER = { "_functionListeners", "_tableListeners" }

local function cloneArray(array)
  local clone = {}
  for k, v in ipairs(array) do clone[k] = v end
  return clone
end

function methods.getOrCreateTable(self, name, listenerType)
  local index = LISTENER_INDEX[listenerType]
  local t = nil
  if index then
    local byName = rawget(self, index) or {}
    rawset(self, index, byName)
    byName[name] = byName[name] or {}
    t = byName[name]
  end
  if t == nil then error("addEventListener: listener cannot be nil: " .. tostring(index)) end
  return t
end
function methods.didRemoveListener(self, name) end
function methods._setHasListener(self, name, value) end
function methods.respondsToEvent(self, name)
  local t = rawget(self, "_functionListeners")
  local result = t and t[name]
  if not result then
    t = rawget(self, "_tableListeners")
    result = t and t[name]
  end
  return result
end
local function listenersOfType(self, l)
  local index = LISTENER_INDEX[type(l)]
  return index and rawget(self, index)
end
function methods.hasEventListener(self, name, l)
  if not l and self[name] then l = self end
  local byName = listenersOfType(self, l)
  for _, x in ipairs(byName and byName[name] or {}) do if rawequal(l, x) then return true end end
  return false
end
function methods.addEventListener(self, name, l)
  if not l and self[name] then l = self end
  local noListeners = not self:respondsToEvent(name)
  table.insert(self:getOrCreateTable(name, type(l)), l)
  if noListeners then self:_setHasListener(name, true) end
  return true
end
function methods.removeEventListener(self, name, l)
  if not l and self[name] then l = self end
  local wasRemoved = false
  local byName = listenersOfType(self, l)
  local ls = byName and byName[name] or {}
  for i = 1, #ls do
    if rawequal(l, ls[i]) then
      table.remove(ls, i)
      wasRemoved = true
      if #ls == 0 then byName[name] = nil end
      self:didRemoveListener(name)
      break
    end
  end
  if not self:respondsToEvent(name) then self:_setHasListener(name, false) end
  return wasRemoved or nil
end
-- dispatchEvent never sets event.target and has no pcall; a listener removed by an earlier one is skipped
function methods.dispatchEvent(self, event)
  local result = false
  local name = event.name
  for _, index in ipairs(DISPATCH_ORDER) do
    local byName = rawget(self, index)
    for _, l in ipairs(cloneArray(byName and byName[name] or {})) do
      if self:hasEventListener(name, l) then
        local handled
        if type(l) == "function" then
          handled = l(event)
        else
          local method = l[name]
          if type(method) == "function" then handled = method(l, event) end
        end
        result = handled or result
      end
    end
  end
  return result
end
function methods.setFillColor(self, r, g, b, a) rawget(self, "__props").fillColor = { r, g, b, a } end
function methods.toFront(self) end

display = {}
function display.newGroup()
  S.groupsCreated = S.groupsCreated + 1
  local g = newDisplayObject("group")
  rawset(g, "__children", {})
  if stage then methods.insert(stage, g) end
  return g
end
function display.newMesh(a, b)
  local params = b or a
  S.meshesCreated = S.meshesCreated + 1
  local m = newDisplayObject("mesh")
  local path = { update = function(path, p) S.meshUpdates = S.meshUpdates + 1 end }
  rawget(m, "__props").path = path
  rawget(m, "__props").x = params.x
  rawget(m, "__props").y = params.y
  if b then methods.insert(a, m) elseif stage then methods.insert(stage, m) end
  return m
end
function display.getCurrentStage() return stage end
display.remove = function(object)   -- verbatim logic of platform/resources/init.lua:569
  if object then
    local method = object.removeSelf
    if "function" == type(method) then method(object) end
  end
end
stage = newDisplayObject("stage")
rawset(stage, "__children", {})

graphics = {}
local TexMT = { __index = {} }
function TexMT.__index.releaseSelf(self)
  if rawget(self, "__released") then error("texture released twice: " .. tostring(self.filename)) end
  rawset(self, "__released", true)
  S.texturesReleased = S.texturesReleased + 1
  S.liveTextures[self] = nil
end
function graphics.newTexture(p)
  local f = io.open(p.filename, "rb")
  if not f then return nil end
  f:close()
  S.texturesCreated = S.texturesCreated + 1
  local t = setmetatable({ type = p.type, filename = p.filename, baseDir = "ResourceDirectory" }, TexMT)
  S.liveTextures[t] = p.filename
  return t
end
function S.liveTextureCount() local n = 0 for _ in pairs(S.liveTextures) do n = n + 1 end return n end

system = { ResourceDirectory = "ResourceDirectory" }
function system.pathForFile(p)
  local f = io.open(p, "rb")
  if not f then return nil end
  f:close()
  return p
end
function system.getTimer() return os.clock() * 1000 end

-- helpers for tests
function S.children(g) return rawget(g, "__children") end
function S.isRemoved(t) return rawget(t, "_proxy") == nil end
function S.gcfull() collectgarbage("collect"); collectgarbage("collect") end
-- S.raises(text, fn, ...): fn(...) must raise an error containing text; prints and returns the message
function S.raises(text, fn, ...)
  local ok, err = pcall(fn, ...)
  print("raises:", ok, err)
  assert(not ok and tostring(err):find(text, 1, true), "expected a raise containing '" .. text .. "', got " .. tostring(ok) .. " " .. tostring(err))
  return err
end

-- Runtime: Solar2D's Runtime is an EventDispatcher (platform/resources/init.lua:337-380), so it takes the same
-- listener methods as a display object; its overrides only toggle hardware listeners. add appends even a duplicate,
-- remove drops the first match.
Runtime = {}
for _, k in ipairs({ "getOrCreateTable", "didRemoveListener", "_setHasListener", "respondsToEvent", "hasEventListener",
                     "addEventListener", "removeEventListener", "dispatchEvent" }) do
  Runtime[k] = methods[k]
end

-- frame boundary: the current frame ends (orphans finalized), the next begins with "enterFrame"
local frameCount = 0
function S.endFrame()
  local ch = rawget(orphanage, "__children")
  while #ch > 0 do
    local t = table.remove(ch)
    rawset(t, "__parent", nil)
    makeUnreachable(t)
  end
end
-- the engine dispatches "enterFrame" under a protected call (librtt/Rtt_Event.cpp:65-80, LuaContext::DoCall): a
-- listener error ends that dispatch and is reported, not raised; S.frame() returns the pcall's results and
-- S.frameErrors counts the reports. The report fails the scenario (tests/lifecycle/run.sh) unless the scenario set
-- S.expectFrameErrors = true before it, which reports as "S.frame: enterFrame (expected): " instead.
S.frameErrors = 0
function S.frame()
  S.endFrame()
  frameCount = frameCount + 1
  local ok, result = pcall(Runtime.dispatchEvent, Runtime, { name = "enterFrame", frame = frameCount, time = system.getTimer() })
  if not ok then
    S.frameErrors = S.frameErrors + 1
    io.stderr:write(S.expectFrameErrors and "S.frame: enterFrame (expected): " or "S.frame: enterFrame: ", tostring(result), "\n")
  end
  return ok, result
end

-- content <-> local transforms (Solar2D obj:localToContent / obj:contentToLocal): each object maps its local point
-- into its parent as T(x, y) * R(rotation degrees, clockwise with y down) * S(xScale, yScale), up the parent chain to
-- the stage. Emulated, not measured: no anchor math, and the properties are read, never written (defaults inside
-- the math).
local function props(t)
  local p = rawget(t, "__props")
  return p.x or 0, p.y or 0, p.xScale or 1, p.yScale or 1, math.rad(p.rotation or 0)
end
local function chain(t)
  local objects = {}
  while t do objects[#objects + 1] = t; t = t.parent end
  return objects
end
function methods.localToContent(self, x, y)
  for _, t in ipairs(chain(self)) do
    local tx, ty, sx, sy, r = props(t)
    local c, s = math.cos(r), math.sin(r)
    x, y = x * sx, y * sy
    x, y = tx + x * c - y * s, ty + x * s + y * c
  end
  return x, y
end
function methods.contentToLocal(self, x, y)
  local objects = chain(self)
  for i = #objects, 1, -1 do
    local tx, ty, sx, sy, r = props(objects[i])
    local c, s = math.cos(r), math.sin(r)
    x, y = x - tx, y - ty
    x, y = (x * c + y * s) / sx, (y * c - x * s) / sy
  end
  return x, y
end
