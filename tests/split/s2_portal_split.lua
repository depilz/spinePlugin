-- render-2 via clipping in split mode: spineboy 'portal' clips the body completely for ~65 frames.
-- split(slots) whose first drawn split slot is fully clipped => the split pass starts with an EMPTY command.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local sets = { { "head" }, { "torso", "head" }, { "portal-bg", "head" } }
local only = tonumber(arg[1])
for i, slots in ipairs(sets) do
  if not only or only == i then
    local scene = display.newGroup()
    local obj = C.spine.create(C.data("spineboy", 0.5)); scene:insert(obj)
    obj:setAnimation(1, "portal", false)
    local sg = obj:split(slots); scene:insert(sg)
    local res = "200 frames ok"
    for f = 1, 200 do
      local ok, err = pcall(C.frame, obj)
      C.mock.endFrame()
      if not ok then res = ("frame %d: draw raised: %s"):format(f, tostring(err):gsub("^.-: ENGINE", "ENGINE"):sub(1, 140)); break end
      local e = C.check(obj, sg, nil, "f" .. f)
      if #e > 0 then res = ("frame %d: oracle: %s"):format(f, e[1]); break end
    end
    print(("split({%s}) + portal: %s"):format(table.concat(slots, ","), res))
    C.expect(res == "200 frames ok", "split + portal clipping (render-2)")
  end
end
C.done()
