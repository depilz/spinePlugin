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
  local t = { _proxy = newproxy(false), __props = {}, __listeners = {}, __kind = kind }
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
  local ls = rawget(t, "__listeners").finalize
  if ls then
    for _, l in ipairs(ls) do
      local ev = { name = "finalize", target = t }
      if type(l) == "function" then l(ev) else l.finalize(l, ev) end
    end
  end
  S.finalized = S.finalized + 1
  rawset(t, "_proxy", nil)
  rawset(t, "_class", nil)
  -- hierarchy is native in Solar2D: drop the stub's Lua-side links so they don't pin anything
  rawset(t, "__parent", nil); rawset(t, "__children", nil); rawset(t, "__props", nil); rawset(t, "__listeners", nil)
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
-- Solar2D's display-object add/removeEventListener reach their helpers through self (platform/resources/init.lua
-- EventDispatcher:addEventListener/removeEventListener, DisplayObject:addEventListener/removeEventListener), so an
-- object that hides the helpers raises there.
function methods.getOrCreateTable(self, name)
  local ls = rawget(self, "__listeners")
  ls[name] = ls[name] or {}
  return ls[name]
end
function methods.didRemoveListener(self, name) end
function methods._setHasListener(self, name, value) end
function methods.respondsToEvent(self, name)
  local ls = rawget(self, "__listeners")[name]
  return ls ~= nil and #ls > 0
end
function methods.addEventListener(self, name, l)
  local noListeners = not self:respondsToEvent(name)
  table.insert(self:getOrCreateTable(name, type(l)), l)
  if noListeners then self:_setHasListener(name, true) end
  return true
end
function methods.removeEventListener(self, name, l)
  local ls = rawget(self, "__listeners")[name]
  if ls then for i = #ls, 1, -1 do if ls[i] == l then table.remove(ls, i); self:didRemoveListener(name) end end end
  if not self:respondsToEvent(name) then self:_setHasListener(name, false) end
end
function methods.dispatchEvent(self, event)
  for _, l in ipairs(rawget(self, "__listeners")[event.name] or {}) do
    if type(l) == "function" then l(event) else l[event.name](l, event) end
  end
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

-- Runtime: Solar2D's EventDispatcher (platform/resources/init.lua) keeps function and table listeners per event
-- name in _functionListeners/_tableListeners, registers a listener once and dispatches over a copy.
Runtime = {}
local LISTENER_FIELDS = { "_functionListeners", "_tableListeners" }
local function listenerList(self, name, l)
  local field = type(l) == "table" and "_tableListeners" or "_functionListeners"
  local byName = rawget(self, field) or {}
  rawset(self, field, byName)
  byName[name] = byName[name] or {}
  return byName[name]
end
function Runtime:hasEventListener(name, l)
  for _, field in ipairs(LISTENER_FIELDS) do
    local byName = rawget(self, field)
    for _, x in ipairs(byName and byName[name] or {}) do if l == nil or rawequal(x, l) then return true end end
  end
  return false
end
function Runtime:addEventListener(name, l)
  if self:hasEventListener(name, l) then return false end
  local ls = listenerList(self, name, l)
  ls[#ls + 1] = l
  return true
end
function Runtime:removeEventListener(name, l)
  local ls = listenerList(self, name, l)
  for i = #ls, 1, -1 do if rawequal(ls[i], l) then table.remove(ls, i) end end
end
function Runtime:dispatchEvent(event)
  for _, field in ipairs(LISTENER_FIELDS) do
    local byName = rawget(self, field)
    local copy = {}
    for i, l in ipairs(byName and byName[event.name] or {}) do copy[i] = l end
    for _, l in ipairs(copy) do
      if type(l) == "function" then l(event) else l[event.name](l, event) end
    end
  end
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
function S.frame()
  S.endFrame()
  frameCount = frameCount + 1
  Runtime:dispatchEvent({ name = "enterFrame", frame = frameCount, time = system.getTimer() })
end
