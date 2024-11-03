local Library = require "CoronaLibrary"

-- Create stub library for simulator
local lib = Library:new{ name='plugin.library', publisherId='com.mycompany' }

-- Default implementations
local function defaultFunction()
end

-- lib.init = defaultFunction
-- lib.show = defaultFunction

lib.shareFile()

print("HElOOO!")

-- Return an instance
return lib
