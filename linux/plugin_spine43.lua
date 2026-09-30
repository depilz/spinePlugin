-- Lua stub shipped as the plugin.spine43 linux-sim archive: the Solar2D Linux Simulator has no native build of the
-- plugin, so `require "plugin.spine43"` loads this library, whose functions only print. The release gate
-- (tools/release-gate/gate.sh) checks that its version is the one in runtime/spine-4.3/spine/Version.h.
local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name='plugin.spine43', publisherId='com.studycat' }
lib.version = 'v3.0.0'

lib.create = function(...)
    print("spine.create()")
end

-- Return an instance
return lib
