-- C.expect(ok, msg): prints and counts a failed check; C.done() raises when any check failed (exit 1).
-- Tests load it with dofile(<their dir>/check.lua); run.sh passes their absolute path as arg[0].
local C = { failed = 0 }
function C.expect(ok, msg)
  if not ok then C.failed = C.failed + 1; print("CHECK FAILED: " .. msg) end
end
function C.done()
  if C.failed > 0 then error(C.failed .. " check(s) failed", 0) end
end
return C
