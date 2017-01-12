
package.path =package.path..";/root/skynet/lualib/?.lua"
package.cpath =package.cpath..";/root/skynet/lualib/?.so"
require("_base")
require("account")
json = require("json")
require("debugger")
local a = account.new({acc="1",1,1})
a.data.b = 1 
a.b = 1
lxz(_base)
a:del()
lxz(_base)
a = a:get()
lxz(a)


