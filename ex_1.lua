
package.path =package.path..";/root/skynet/lualib/?.lua"
local mod = require("myobj")
require("debugger")
obj = mod.new("test",{_id=1, pid=1,account="my"})
lxz(obj)
obj.pid= 2
lxz(obj)
lxz(mod.save)
