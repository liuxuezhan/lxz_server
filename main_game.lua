local skynet = require "skynet"
local cluster = require "cluster"
local json = require "json"

--pause("debug in main_loop")

skynet.start(function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)

   -- skynet.newservice("login",_conf.login1)
    skynet.newservice("db_mongo",_conf.db1)--数据库写中心
	local s = skynet.newservice("gateserver",_conf.game1)
	cluster.register("game1_1", s)
	cluster.open "game1"

    skynet.exit()
end)

