local skynet = require "skynet"

skynet.start (
function()

    require "skynet.manager"
    skynet.register("log_server")
    skynet.dispatch("lua", function(_,source,command, ...)--服务器间通信,包括集群

    end)

end
)

