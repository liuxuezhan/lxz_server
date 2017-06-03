
package.path =package.path..";lualib/?.lua"
package.cpath =package.cpath..";/root/skynet/lualib/?.so"
require("base")
require("account")
json = require("json")
require("debugger")
local a = {}
a.b = account.new({acc="1",1,1})
a.b.save.b.c.d.e = {1} 
a.b.save.b.c.d.e.f = 1 
lxz(base)
--a:del()
a.b.save.b.c = nil 
lxz(base)
a = a.b:get()
lxz(a)

