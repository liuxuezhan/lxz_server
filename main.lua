local skynet = require "skynet"
local json = require "json"

--pause("debug in main_loop")

skynet.start(function()
    local console = skynet.newservice("console")
    skynet.newservice("debug_console",80000)

    skynet.newservice("logind",json.encode(_conf.login[1]))

	skynet.newservice("gateserver",json.encode(_conf.server[1]))

    skynet.newservice("room",json.encode(_conf.room[1]))

    skynet.newservice("db_mongo",json.encode(_conf.db[1]))--数据库写中心

    skynet.exit()
end)

