
package.path =package.path..";/root/skynet/lualib/?.lua"
local mod = require("myobj")
require("debugger")
json = require("json")
obj = mod.one("json",{_id=1, pid=1,account="my"})
obj.encode({1})
lxz(obj)
obj.pid= 2
lxz(obj)
lxz(mod.save)
