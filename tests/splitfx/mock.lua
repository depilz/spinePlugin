-- Solar2D mock for the split oracle of the split and probe-batching suites (extends tests/render/mock_solar2d.lua).
-- Semantics from Solar2D source (coronalabs/corona @87f5a3d2):
--  * group:insert(index, child): Rtt_GroupObject.cpp:328-397 (out-of-range -> append; new parent -> child released
--    from old parent; same parent -> move). Inserting into itself -> luaL_error (Rtt_LuaProxyVTable.cpp:3875/3917).
--  * obj:removeSelf() does NOT finalize synchronously: the object is moved to the Orphanage
--    (Rtt_LuaProxyVTable.cpp:3936-4000) and finalized at the end of the frame (Rtt_Runtime.cpp:2044-2048 ->
--    Display::Collect -> GroupObject::CollectUnreachables, Rtt_GroupObject.cpp:28-66). Children of a removed group
--    are finalized with it. After finalize the table is a plain table (no metatable).
--  * obj.parent is nil for a removed object even before finalize (Rtt_LuaProxyVTable.cpp:920-945). Its DESCENDANTS
--    keep reporting their parent until they are finalized at the end of the frame (verified in the real Simulator:
--    work/split/sim/results/semantics_150.txt, E2).
--  * An object in the Orphanage can be re-inserted into a live group before the end of the frame (Insert releases it
--    from its old parent), which rescues it.
--  * Engine APIs called with a finalized (plain) table or a non-group self raise from C++; in the Mac Simulator these
--    abort the process even inside pcall (gap-3 s9a/S3). The mock raises "ENGINE-ABORT: ..." for those.
--  * object.fill = {...} creates a new Paint (blend reset to normal).
local M = { stats = {}, live = { meshes = 0, textures = 0 }, warnings = {}, deferred = true, orphans = {}, finalized = 0 }
local stats = M.stats
local function bump(k, n) stats[k] = (stats[k] or 0) + (n or 1) end
function M.resetStats() for k in pairs(stats) do stats[k] = nil end end

local props = setmetatable({}, { __mode = "k" })
M.props = props
local function P(o) local p = props[o]; if not p then p = {}; props[o] = p end; return p end

local GroupMethods, MeshMethods = {}, {}
local groupMt, meshMt = {}, {}
local stage

local function engineAbort(msg) error("ENGINE-ABORT: " .. msg, 3) end

local function onscreen(o)
  local p = props[o]
  while p do
    if p.orphan then return false end
    if o == stage then return true end
    o = p.parent; if not o then return false end
    p = props[o]
  end
  return false
end
M.onscreen = onscreen

local function detach(child)
  local cp = props[child]; if not cp then return end
  local parent = cp.parent
  if parent and props[parent] then
    local ch = props[parent].children
    for i = 1, #ch do if ch[i] == child then table.remove(ch, i); break end end
  end
  cp.parent = nil
end

local function insert(self, a, b)
  local sp = props[self]
  if not sp or not sp.children then
    engineAbort("group.insert called with a non-group self (" .. tostring(sp and sp.kind or type(self)) .. ")")
  end
  local index, child
  if b == nil or type(b) == "boolean" then child = a; index = 0 else index = a; child = b end
  if type(child) ~= "table" or not props[child] then engineAbort("group.insert: child is not a display object (luaproxy expected)") end
  if child == self then engineAbort("attempt to insert display object into itself") end
  local n = #sp.children
  local idx = (index == 0) and n or (index - 1)
  if idx > n or idx < 0 then bump("insertOutOfRange"); idx = n end
  local cp = props[child]
  if cp.orphan then cp.orphan = nil; bump("rescuedFromOrphanage") end
  if cp.parent ~= self then
    detach(child); cp.parent = self
    table.insert(sp.children, idx + 1, child)
  else
    local old
    for i = 1, n do if sp.children[i] == child then old = i - 1; break end end
    if idx ~= old then
      table.remove(sp.children, old + 1)
      if old < idx then idx = idx - 1 end
      table.insert(sp.children, idx + 1, child)
    end
  end
end
function GroupMethods.insert(self, a, b) bump("insert"); if M.onInsert then M.onInsert(self, a, b) end; insert(self, a, b) end -- onInsert: debug hook

local function finalize(o)
  local p = props[o]; if not p then return end
  if p.children then for i = #p.children, 1, -1 do finalize(p.children[i]) end end
  if p.listeners and p.listeners.finalize then
    for _, fn in ipairs(p.listeners.finalize) do
      local ev = { name = "finalize", target = o }
      if type(fn) == "function" then fn(ev) elseif type(fn) == "table" and fn.finalize then fn:finalize(ev) end
    end
  end
  if p.kind == "mesh" then M.live.meshes = M.live.meshes - 1 end
  M.finalized = M.finalized + 1
  props[o] = nil
  setmetatable(o, nil)
end

local function remove(o)
  local p = props[o]
  if not p then engineAbort("removeSelf: luaproxy expected (object already finalized)") end
  if p.orphan or not onscreen(o) and p.parent == nil then return end -- already removed this frame: no-op (gap-3 s16)
  detach(o)
  if M.deferred then
    p.orphan = true
    M.orphans[#M.orphans + 1] = o
  else
    finalize(o)
  end
end
function GroupMethods.removeSelf(self) bump("groupRemoveSelf"); remove(self) end
function MeshMethods.removeSelf(self) bump("meshRemoveSelf"); remove(self) end
function GroupMethods.remove(self, c) local sp = props[self]; if not sp then engineAbort("remove") end
  if type(c) == "number" then c = sp.children[c] end; if c then remove(c) end end

timer = { pending = {} }
function timer.performWithDelay(ms, fn) local t = { fn = fn }; timer.pending[#timer.pending + 1] = t; return t end

-- end of frame: collect the orphanage (Display::Collect); then run timers queued during the frame (next frame)
function M.endFrame()
  local due = timer.pending; timer.pending = {}
  for _, t in ipairs(due) do t.fn({ name = "timer" }) end
  local list = M.orphans; M.orphans = {}
  for _, o in ipairs(list) do
    local p = props[o]
    if p and p.orphan then finalize(o) end
  end
end

function MeshMethods.setFillColor(self, r, g, b, a)
  bump("setFillColor")
  local p = props[self]; if not p then engineAbort("setFillColor on finalized object") end
  p.paint.color = { r, g or r, b or r, a or 1 }
end
local function addEventListener(self, name, fn)
  local p = props[self]; if not p then engineAbort("addEventListener on finalized object") end
  p.listeners = p.listeners or {}
  p.listeners[name] = p.listeners[name] or {}
  table.insert(p.listeners[name], fn)
end
GroupMethods.addEventListener = addEventListener
MeshMethods.addEventListener = addEventListener
GroupMethods.hasEventListener = function(self, name) local p = props[self]; return p and p.listeners and p.listeners[name] and #p.listeners[name] > 0 end
MeshMethods.hasEventListener = GroupMethods.hasEventListener
function GroupMethods.toFront(self) local p = props[self]; if p and p.parent then insert(p.parent, self) end end
MeshMethods.toFront = GroupMethods.toFront

local function commonIndex(t, k, p)
  if k == "parent" then if p.orphan then return nil end return p.parent end
  if k == "stage" then if p.orphan then return nil end return stage end
  return nil
end

groupMt.__index = function(t, k)
  local m = GroupMethods[k]; if m then return m end
  local p = props[t]; if not p then return nil end
  if k == "numChildren" then return #p.children end
  if k == "parent" or k == "stage" then return commonIndex(t, k, p) end
  if type(k) == "number" then return p.children[k] end
  return p.fields and p.fields[k]
end
groupMt.__newindex = function(t, k, v) local p = P(t); p.fields = p.fields or {}; p.fields[k] = v end

local function newPaint(spec)
  bump("newPaint")
  return { spec = spec, blendMode = "normal", color = { 1, 1, 1, 1 } }
end
local function fillProxy(paint)
  return setmetatable({}, {
    __index = function(_, k) if k == "effect" then return paint.effectProxy end return paint[k] end,
    __newindex = function(_, k, v)
      if k == "effect" then
        bump("effectSet")
        if v == nil then paint.effect, paint.effectProxy = nil, nil
        else
          paint.effect = { name = v, params = {} }
          paint.effectProxy = setmetatable({}, { __index = paint.effect.params,
            __newindex = function(_, kk, vv) bump("effectParamSet"); paint.effect.params[kk] = vv end })
        end
      else paint[k] = v end
    end })
end

meshMt.__index = function(t, k)
  local m = MeshMethods[k]; if m then return m end
  local p = props[t]; if not p then return nil end
  if k == "parent" or k == "stage" then return commonIndex(t, k, p) end
  if k == "path" then return p.path end
  if k == "fill" then return p.fillProxy end
  if k == "blendMode" then return p.paint.blendMode end
  return p.fields[k]
end
meshMt.__newindex = function(t, k, v)
  local p = P(t)
  if k == "fill" then bump("fillSet"); p.paint = newPaint(v); p.fillProxy = fillProxy(p.paint); return end
  if k == "blendMode" then bump("blendSet"); p.paint.blendMode = v; return end
  p.fields = p.fields or {}
  p.fields[k] = v
end

local function pathUpdate(path, params)
  bump("pathUpdate")
  local p = props[path.owner]
  if not p then engineAbort("path:update on finalized mesh") end
  local n = params.vertices and params.vertices.count
  p.vertexCount = n
end

display = {}
function display.newGroup()
  bump("newGroup")
  local g = setmetatable({}, groupMt)
  local p = P(g); p.kind = "group"; p.children = {}; p.fields = {}
  if stage then insert(stage, g) end
  return g
end
stage = display.newGroup(); M.stage = stage; stats.newGroup = 0
function display.getCurrentStage() return stage end
function display.newMesh(params)
  bump("newMesh")
  local o = setmetatable({}, meshMt)
  local p = P(o); p.kind = "mesh"; p.fields = { x = params.x, y = params.y }
  p.paint = newPaint(nil); p.fillProxy = fillProxy(p.paint)
  p.path = { update = pathUpdate, owner = o }
  p.vertexCount = params.vertices and params.vertices.count
  p.mode = params.mode
  M.live.meshes = M.live.meshes + 1
  insert(stage, o)
  return o
end
function display.newRect(x, y, w, h)
  local o = setmetatable({}, meshMt)
  local p = P(o); p.kind = "rect"; p.fields = { x = x, y = y }
  p.paint = newPaint(nil); p.fillProxy = fillProxy(p.paint); p.path = {}
  insert(stage, o)
  return o
end
function display.remove(o)
  if o then
    local m = o.removeSelf
    if type(m) == "function" then m(o) end
  end
end

graphics = {}
function graphics.newTexture(params)
  bump("newTexture"); M.live.textures = M.live.textures + 1
  local tex = { type = params.type, filename = params.filename, baseDir = params.baseDir }
  function tex:releaseSelf() bump("releaseTexture"); M.live.textures = M.live.textures - 1 end
  return tex
end

system = {}
function system.pathForFile(path, baseDir)
  local f = io.open(path, "rb"); if f then f:close(); return path end
  return nil
end
function system.getTimer() return os.clock() * 1000 end

-- helpers
function M.kind(o) local p = props[o]; return p and p.kind end
function M.children(g) local p = props[g]; return p and p.children or {} end
function M.parentOf(o) local p = props[o]; return p and p.parent end
function M.paint(o) local p = props[o]; return p and p.paint end
function M.isFinalized(o) return props[o] == nil end
function M.isOrphan(o) local p = props[o]; return p and p.orphan end
function M.vertexCount(o) local p = props[o]; return p and p.vertexCount end

local blendNames = { [0] = "normal", [1] = "add", [2] = "multiply", [3] = "screen" }
M.blendNames = blendNames

-- Compare a group's mesh children (in order) with the expected (batched) command list.
function M.compare(group, cmds, label)
  local out = {}
  local meshes = {}
  for _, c in ipairs(M.children(group)) do if M.kind(c) == "mesh" then meshes[#meshes + 1] = c end end
  local exp = {}
  for _, c in ipairs(cmds or {}) do if c.numIndices >= 3 then exp[#exp + 1] = c end end
  if #meshes ~= #exp then out[#out + 1] = ("%s: %d meshes in group, %d drawable commands"):format(label, #meshes, #exp) end
  for i = 1, math.min(#meshes, #exp) do
    local m, c = meshes[i], exp[i]
    local p = props[m]
    local wantBlend = blendNames[c.blend]
    if p.paint.blendMode ~= wantBlend then out[#out + 1] = ("%s #%d: blend %s, expected %s"):format(label, i, p.paint.blendMode, wantBlend) end
    local tex = p.paint.spec and p.paint.spec.filename
    if tex ~= c.tex then out[#out + 1] = ("%s #%d: texture %s, expected %s"):format(label, i, tostring(tex), tostring(c.tex)) end
    if p.vertexCount ~= c.numIndices then out[#out + 1] = ("%s #%d: %d vertices, expected %d"):format(label, i, p.vertexCount or -1, c.numIndices) end
    local col = c.color
    local a = math.floor(col / 16777216) % 256
    local r = math.floor(col / 65536) % 256
    local g = math.floor(col / 256) % 256
    local b = col % 256
    local pc = p.paint.color
    local function near(x, y) return math.abs(x - y / 255) < 0.003 end
    if not (near(pc[1], r) and near(pc[2], g) and near(pc[3], b) and near(pc[4], a)) then
      out[#out + 1] = ("%s #%d: color %.3f,%.3f,%.3f,%.3f expected %d,%d,%d,%d/255"):format(label, i, pc[1], pc[2], pc[3], pc[4], r, g, b, a)
    end
  end
  return out
end

return M
