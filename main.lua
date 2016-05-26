local skynet = require "skynet"
local json = require "json"

--pause("debug in main_loop")

skynet.start(function()
    local console = skynet.newservice("console")
    skynet.newservice("debug_console",80000)

    skynet.newservice("db_mongo","db_login")--数据库写中心

    skynet.newservice("login",1)

	skynet.newservice("gateserver",1)

    skynet.exit()
end)

