
package.path =package.path..";lualib/?.lua"
package.cpath =package.cpath..";/root/skynet/lualib/?.so"
require("base")
require("account")
json = require("json")
require("debugger")
local a = account.new({acc="1",1,1})
a.save.b.c.d.e = {1} 
a.save.b.c.d.e.f = 1 
a.b = 2
lxz(base)
--a:del()
a.save.b.c = nil 
lxz(base)
a = a:get()
lxz(a)


