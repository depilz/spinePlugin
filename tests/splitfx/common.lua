-- Shared by the split and probe-batching tests: the Solar2D mock, the plugin, the splitfx inspection module, the
-- oracle and tests/check.lua's C.expect/C.done. Tests load it with dofile(<their dir>/../splitfx/common.lua); run.sh
-- passes their absolute path as arg[0].
local W = arg[0]:match("^(.*)/") .. "/../splitfx"
package.path = W .. "/?.lua;" .. package.path
local C = dofile(W .. "/../check.lua")
C.mock = require("mock")
C.spine, C.fx = require("plugin_spine"), require("splitfx")
local mock, spine, fx = C.mock, C.spine, C.fx

local function exists(p) local f = io.open(p, "rb"); if f then f:close(); return true end return false end
local cache = {}
-- C.data(name, scale): the skeleton data of <name>/<file>.skel (else .json) with <name>/<file>.atlas, where <file> is
-- the last path component of name (an example name, or a rig directory path such as C.SEQUENCE's)
function C.data(name, scale)
  local key = name .. "@" .. (scale or 1)
  if cache[key] then return cache[key] end
  local base = ("%s/%s"):format(name, name:match("[^/]+$"))
  local atlasPath, skelPath = base .. ".atlas", base .. ".skel"
  if not exists(skelPath) then skelPath = base .. ".json" end
  local atlas = spine.loadAtlas(atlasPath)
  local d = spine.loadSkeletonData(skelPath, atlas, scale or 1)
  cache[key] = d
  return d
end

-- the line's sequence rig as a rig-list entry { name, exts = its exports }: 4.2 has no Esoteric sequence rig, so the
-- generated fixture (JSON only), loaded by its directory path; 4.3 the diamond example
C.SEQUENCE = ({
  ["4.2"] = { W .. "/../lifecycle/assets/4.2/sequence", exts = { "json" } },
  ["4.3"] = { "diamond", exts = { "skel", "json" } },
})[os.getenv("SPINE_RUNTIME")]
assert(C.SEQUENCE, "no sequence rig for SPINE_RUNTIME " .. tostring(os.getenv("SPINE_RUNTIME")))

local function append(a, b) for _, e in ipairs(b) do a[#a + 1] = e end end

-- sum of mesh vertex counts in a group's children (in order), optionally stopping at a child
local function meshPrefix(group, stopAt)
  local n = 0
  for _, c in ipairs(mock.children(group)) do
    if c == stopAt then return n, true end
    if mock.kind(c) == "mesh" then n = n + (mock.vertexCount(c) or 0) end
  end
  return n, stopAt == nil
end

-- Oracle. obj: spine object; sg: split group returned by split() (or nil); injs: { {obj=displayObject, slot=name}, ... }
function C.check(obj, sg, injs, label)
  local errs = {}
  label = label or "?"
  local main, split = fx.expected(obj)
  append(errs, mock.compare(obj, main, label .. "/main"))
  if split then
    if not sg then errs[#errs + 1] = label .. ": split mode but test has no split group"
    elseif mock.isFinalized(sg) then errs[#errs + 1] = label .. ": plugin still in split mode but its split group was finalized"
    else append(errs, mock.compare(sg, split, label .. "/split")) end
  elseif sg and not mock.isFinalized(sg) then
    local n = 0
    for _, c in ipairs(mock.children(sg)) do if mock.kind(c) == "mesh" then n = n + 1 end end
    if n > 0 then errs[#errs + 1] = ("%s: not split, but the (live) split group still holds %d meshes"):format(label, n) end
  end
  -- renderer-independent checks against the unbatched per-slot reference
  local ref = fx.reference(obj)
  local tot = { 0, 0 }
  for _, r in ipairs(ref) do tot[r.group] = tot[r.group] + r.n end
  local groups = { obj, split and sg or nil }
  for gi = 1, 2 do
    local g = groups[gi]
    if g then
      local have = meshPrefix(g)
      if have ~= tot[gi] then errs[#errs + 1] = ("%s: group %d draws %d vertices, reference %d"):format(label, gi, have, tot[gi]) end
    end
  end
  for _, inj in ipairs(injs or {}) do
    local o = inj.obj
    if not mock.isFinalized(o) and mock.onscreen(o) then
      local want, pre = nil, { 0, 0 }
      for _, r in ipairs(ref) do
        pre[r.group] = pre[r.group] + r.n
        if r.name == inj.slot then want = { group = r.group, prefix = pre[r.group] } end
      end
      if want then
        local g = groups[want.group]
        local parent = mock.parentOf(o)
        if parent ~= g then
          errs[#errs + 1] = ("%s: injected object for slot %s is in the wrong group (want %s)"):format(label, inj.slot, want.group == 1 and "skeleton" or "split")
        else
          local have = meshPrefix(g, o)
          if have ~= want.prefix then
            errs[#errs + 1] = ("%s: injected object for slot %s drawn after %d vertices, reference %d"):format(label, inj.slot, have, want.prefix)
          end
        end
      end
    end
  end
  -- meshes the plugin references must be live, and every live mesh on screen must belong to obj or sg
  for _, m in ipairs(fx.meshRefs(obj)) do
    if mock.isFinalized(m) then errs[#errs + 1] = label .. ": plugin references a finalized mesh (next draw will fail)"; break end
  end
  return errs
end

-- count meshes on screen that are not children of obj / sg (orphaned plugin meshes left visible)
function C.strayMeshes(obj, sg)
  local n = 0
  local function walk(g)
    for _, c in ipairs(mock.children(g)) do
      if mock.kind(c) == "mesh" then
        local p = mock.parentOf(c)
        if p ~= obj and p ~= sg then n = n + 1 end
      elseif mock.kind(c) == "group" then walk(c) end
    end
  end
  walk(mock.stage)
  return n
end

function C.frame(obj, dt)
  obj:updateState(dt or 16.666)
  obj:draw()
end

function C.slotNames(obj)
  return obj:getSlotNames()
end

return C
