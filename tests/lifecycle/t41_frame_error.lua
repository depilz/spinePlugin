-- An enterFrame listener raises once. arg[1] "expected" sets S.expectFrameErrors first, "unexpected" does not.
-- suite.sh runs it straight through the host, not run.sh (whose report grep fails the unexpected one on its own):
-- the host must exit 1 on the unexpected error and 0 on the expected one.
local S = __stub
S.expectFrameErrors = arg[1] == "expected"
local function boom()
  Runtime:removeEventListener("enterFrame", boom)
  error("boom in enterFrame")
end
Runtime:addEventListener("enterFrame", boom)
S.frame()
S.frame()
print(("%s: frame errors %d"):format(arg[1], S.frameErrors))
