-- Tint-black dark bytes round instead of truncating (D12): coin's coin-front-shine slot keys dark 7e7e7e at 0.2666667 s
-- and fades linearly to 000000 at 0.664 s. Exactly on the key the channel is 126.0 either way, so sample 0.5 ms after
-- it: 125.84 per channel, which must read 0xff7e7e7e (rounded), not 0xff7d7d7d (truncated).
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local fx = C.fx

local obj = C.spine.create(C.data("coin"))
obj:setAnimation(1, "animation", false)
C.frame(obj, 266.6667 + 0.5)
local darks = {}
for _, c in ipairs((fx.expected(obj))) do
  local dark = ("%08x"):format(c.dark)   -- compared as text: Lua 5.1 keys numeric constants by int (UBSan)
  if dark ~= "ff000000" then darks[#darks + 1] = dark end
end
print("tint-black dark colours: " .. table.concat(darks, " "))
C.expect(#darks == 1, "expected exactly one tint-black command (coin-front-shine)")
C.expect(darks[1] == "ff7e7e7e", "coin's 7e dark byte does not read 126 (truncated instead of rounded?)")
C.done()
