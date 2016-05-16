
local skynet = require "skynet"

--pause("debug in main_loop")

skynet.start(function()
    lxz()
    local console = skynet.newservice("console")
    skynet.newservice("debug_console",80000)


	local gate = skynet.newservice("gated")

	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})
    skynet.exit()
end)

