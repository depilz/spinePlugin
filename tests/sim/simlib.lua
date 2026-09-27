-- Scenario helper. suite.sh writes scenario.txt into the project: the script, its argument and the results file.
-- Results lines are TAB-separated; suite.sh reads "DONE exit", "UNHANDLED_ERROR", "ERROR" and "CHECK" lines.
local M = {}
do
  local f = assert(io.open(system.pathForFile("scenario.txt", system.ResourceDirectory)))
  M.script, M.arg, M.out = f:read("*l", "*l", "*l")
  f:close()
  M.dir = M.out:match("^(.*)/")
end
function M.open(name)
  M.name = name
  M.f = assert(io.open(M.out, "w"))
  M.log("scenario", name)
  M.log("system.getInfo('build')", system.getInfo("build"))
  M.log("platform", system.getInfo("platform"), system.getInfo("environment"), system.getInfo("model"))
  Runtime:addEventListener("unhandledError", function(e)
    M.log("UNHANDLED_ERROR", e.errorMessage, e.stackTrace)
    return true -- suppress the modal alert
  end)
  M.t0 = system.getTimer(); M.frames = 0
  Runtime:addEventListener("enterFrame", function() M.frames = M.frames + 1 end)
  timer.performWithDelay(M.watchdogMs or 60000, function() M.log("WATCHDOG timeout"); M.finish(3) end)
end
function M.log(...)
  local t = {}
  for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
  local s = table.concat(t, "\t")
  if M.f then M.f:write(s, "\n"); M.f:flush() end
  print("[sim] " .. s)
end
-- check(name, ok, detail...): one recorded check, test id "<scenario test> <name>"
function M.check(name, ok, ...)
  M.log("CHECK", ok and "PASS" or "FAIL", name, ...)
end
function M.loadPlugin(name)
  name = name or "plugin.spine42"
  local ok, spine = pcall(require, name)
  M.log("require('" .. name .. "')", ok, type(spine), (not ok) and tostring(spine) or "")
  M.log("package.cpath", package.cpath)
  return spine
end
function M.finish(code)
  M.log(("frames %d in %.0f ms (%.1f fps)"):format(M.frames or 0, system.getTimer() - (M.t0 or 0), (M.frames or 0) * 1000 / math.max(1, system.getTimer() - (M.t0 or 0))))
  M.log("DONE exit", code or 0)
  if M.f then M.f:close(); M.f = nil end
  io.stdout:flush()
  os.exit(code or 0)
end
return M
