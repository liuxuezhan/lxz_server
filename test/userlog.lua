local skynet = require "skynet"
require "skynet.manager"

skynet.register_protocol {
    name = "text",
    id = skynet.PTYPE_TEXT,
    unpack = skynet.tostring,
    dispatch = function(_, address, msg)
        local str =string.format("uselog-%x(%s-%s): %s", address,os.date("%X",math.floor(skynet.time())), skynet.time(), msg)
        print(str)
	save_file( "a","debug".."_"..os.date("%Y").."_"..os.date("%m").."_"..os.date("%d")..".log",str)
    end
}

skynet.start(function()
    skynet.register ".logger"
end)