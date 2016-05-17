
local skynet = require "skynet"

--pause("debug in main_loop")

skynet.start(function()
    local console = skynet.newservice("console")
    skynet.newservice("debug_console",80000)

	local msg = skynet.newservice("gateserver")
	skynet.call(msg, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})
    skynet.exit()
end)

