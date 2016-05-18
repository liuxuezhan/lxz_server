
local skynet = require "skynet"

--pause("debug in main_loop")

skynet.start(function()
    local console = skynet.newservice("console")
    skynet.newservice("debug_console",80000)

    local login = "ssss"
    skynet.newservice("logind",login)

    local server1 = "server1"
	skynet.newservice("gateserver",login,server1)
	skynet.call(server1, "lua", "open" , {
		port = 8888,
		maxclient = 64,
	})
    skynet.exit()
end)

