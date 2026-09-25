-- SpineTextureLoader ref-counting when two atlases share a page image.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, spine = C.mock, C.spine
local function gc() for i = 1, 4 do collectgarbage("collect") end end
local function report(label) print(("%-58s newTexture=%d releaseSelf=%d live=%d"):format(label, mock.stats.newTexture or 0, mock.stats.releaseTexture or 0, mock.live.textures)) end

-- Case A: single atlas, load + release
local live0 = mock.live.textures
do local a = spine.loadAtlas("raptor/raptor.atlas"); report("A: raptor.atlas loaded"); a = nil end
gc(); report("A: released + GC")
C.expect(mock.live.textures == live0, "A: texture not released")

-- Case B: same atlas file loaded twice (e.g. two modules each loading it), release both
mock.resetStats()
do
  local a1 = spine.loadAtlas("spineboy/spineboy.atlas")
  local a2 = spine.loadAtlas("spineboy/spineboy.atlas")
  report("B: spineboy.atlas loaded twice")
  a1, a2 = nil, nil
end
gc(); report("B: both released + GC (expect releaseSelf=1, live back)")
C.expect(mock.live.textures == live0, "B: shared texture not released (render-9)")
live0 = mock.live.textures

-- Case C: load twice, release second first
mock.resetStats()
local b1 = spine.loadAtlas("goblins/goblins.atlas")
do local b2 = spine.loadAtlas("goblins/goblins.atlas"); b2 = nil end
gc(); report("C: goblins x2, second released")
b1 = nil; gc(); report("C: first released too")
C.expect(mock.live.textures == live0, "C: shared texture not released (render-9)")
C.done()
