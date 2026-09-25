-- S5: PMA atlas vs straight atlas rendered by the real Solar2D renderer.
local L = require("simlib")
L.watchdogMs = 30000
L.open("s5_pma")
local OUTDIR = L.dir .. "/"
local spine = L.loadPlugin()
L.log("content", display.contentWidth, display.contentHeight, "pixel", display.pixelWidth, display.pixelHeight, "contentScaleX", display.contentScaleX)
local skelPath = "spines/spineboy/spineboy.skel"
local variants = {
  { key = "straight", atlas = "spines/spineboy/spineboy.atlas" },
  { key = "pma", atlas = "spines/spineboy/spineboy-pma.atlas" },
}
local bgs = { black = { 0, 0, 0 }, white = { 1, 1, 1 }, grey = { 0.5, 0.5, 0.5 } }
local W, H = 700, 760
local function copyOut(name)
  local src = system.pathForFile(name, system.TemporaryDirectory)
  local fi = io.open(src, "rb"); if not fi then L.log("missing", src); return end
  local bytes = fi:read("*a"); fi:close()
  local fo = assert(io.open(OUTDIR .. "s5_" .. name, "wb")); fo:write(bytes); fo:close()
  L.log("saved", name, #bytes, "bytes ->", OUTDIR .. "s5_" .. name)
end
local jobs = {}
for _, v in ipairs(variants) do
  local atlas = spine.loadAtlas(v.atlas)
  local data = spine.loadSkeletonData(skelPath, atlas, 1)
  for bgName, c in pairs(bgs) do
    jobs[#jobs + 1] = function()
      local g = display.newGroup()
      local bg = display.newRect(g, display.contentCenterX, display.contentCenterY, W, H)
      bg:setFillColor(c[1], c[2], c[3])
      local obj = spine.create(data)
      g:insert(obj)
      obj.x, obj.y = display.contentCenterX, display.contentCenterY + 330
      obj:setAnimation(1, "idle", false)
      obj:updateState(0)
      obj:draw()
      local name = v.key .. "_" .. bgName .. ".png"
      display.save(g, { filename = name, baseDir = system.TemporaryDirectory, captureOffscreenArea = true })
      copyOut(name)
      obj:removeSelf()
      g:removeSelf()
    end
  end
end
local i = 0
local function nextJob()
  i = i + 1
  if jobs[i] then
    local ok, err = pcall(jobs[i]); if not ok then L.log("ERROR", "job", err) end
    timer.performWithDelay(50, nextJob)
  else
    L.finish(0)
  end
end
timer.performWithDelay(100, nextJob)
