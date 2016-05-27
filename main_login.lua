local skynet = require "skynet"
local cluster = require "cluster"
local json = require "json"

--pause("debug in main_loop")

skynet.start(function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)

    local l = skynet.newservice("login",_conf.login1)
	cluster.register("login1_1", l)
	cluster.open "login1"
   -- skynet.newservice("db_mongo",_conf.db1)--数据库写中心
--	skynet.newservice("gateserver",_conf.game1)

    skynet.exit()
end)

