-- Alpha-0 paths in the vendored renderer (D11): a slot hidden with slot.alpha = 0 emits no geometry, and an injection
-- slot on any alpha-0 path (slot.alpha, Spine slot colour, region or mesh attachment colour) still gets its placeholder
-- command, so the injected object is placed and its listener sees isVisible = true every frame (D114).
-- arg[1]: "vertices" | "solar" (arg[2] region|mesh) | "slot-color" | "mesh-color" (arg[2] region|mesh, default mesh)
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local fx, mock = C.fx, C.mock

local obj = C.spine.create(C.data("raptor", 0.5))
C.frame(obj)
local function firstSlot(kind)
  for _, name in ipairs(obj:getDrawOrder()) do
    local slot = obj:getSlot(name)
    if slot.attachment and slot.attachment.type == kind then return slot end
  end
end
-- what the renderer produces now: total vertices, commands carrying an injection slot, and their vertices
local function totals()
  local main, split = fx.expected(obj)
  local vertices, injected, injectedVertices = 0, 0, 0
  for _, list in ipairs({ main, split or {} }) do
    for _, c in ipairs(list) do
      vertices = vertices + c.numVertices
      if c.injectionSlot >= 0 then injected, injectedVertices = injected + 1, injectedVertices + c.numVertices end
    end
  end
  return vertices, injected, injectedVertices
end

if arg[1] == "vertices" then
  for _, kind in ipairs({ "region", "mesh" }) do
    local slot = firstSlot(kind)
    local shown = totals()
    slot.attachment.color = { a = 0 }   -- the existing attachment-alpha early-out: the slot's geometry is dropped
    C.frame(obj)
    local withoutSlot = totals()
    slot.attachment.color = { a = 1 }
    slot.alpha = 0
    C.frame(obj)
    local hidden = totals()
    print(("%s slot '%s': vertices shown %d, without the slot %d, slot.alpha = 0 %d"):format(kind, slot.name, shown,
      withoutSlot, hidden))
    C.expect(withoutSlot < shown and hidden == withoutSlot, kind .. ": slot.alpha = 0 still emits the slot's geometry")
    C.expect(#C.check(obj, kind) == 0, kind .. ": drawn meshes differ from the renderer's commands")
    slot.alpha = 1
    C.frame(obj)
    C.expect(totals() == shown, kind .. ": slot.alpha = 1 does not restore the slot's geometry")
  end
  C.done()
  return
end

local mode = arg[1]
local slot = firstSlot(arg[2] or mode == "mesh-color" and "mesh" or "region")
local hide = ({
  solar = function(a) slot.alpha = a end,
  ["slot-color"] = function(a) fx.slotColorAlpha(obj, slot.name, a) end,
  ["mesh-color"] = function(a) slot.attachment.color = { a = a } end,
})[mode]
local calls
local marker = display.newRect(0, 0, 10, 10)
obj:inject(marker, slot.name, function(e) calls[#calls + 1] = e.isVisible and "T" or "F" end)
local placeholderFrames = 0
local function frames(label, n, group, hidden)
  for f = 1, n do
    calls = {}
    C.frame(obj)
    local _, injected, injectedVertices = totals()
    local got = table.concat(calls)
    C.expect(got == "T", ("%s frame %d: listener calls {%s}, expected {T} (D114)"):format(label, f, got))
    C.expect(mock.parentOf(marker) == group, ("%s frame %d: injected object not placed in its group"):format(label, f))
    C.expect(#C.check(obj, label) == 0, label .. ": drawn meshes differ from the renderer's commands")
    if hidden then
      C.expect(injectedVertices == 0, ("%s frame %d: the hidden slot still emits geometry"):format(label, f))
      if injected > 0 then placeholderFrames = placeholderFrames + 1 end
    end
  end
end
frames("shown", 2, obj)
hide(0)
frames("hidden", 3, obj, true)
local g = obj:split({ slot.name })
obj._splitGroup = g
frames("hidden, split", 2, g, true)
obj:reassemble()
obj._splitGroup = nil
hide(1)
frames("re-shown", 2, obj)
print(("%s, %s slot '%s': placeholder frames %d of 5"):format(mode, slot.attachment.type, slot.name, placeholderFrames))
C.expect(placeholderFrames == 5, "placeholder missing on a hidden frame")
C.done()
