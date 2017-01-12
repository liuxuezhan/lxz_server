
package.path =package.path..";/root/skynet/lualib/?.lua"
package.cpath =package.cpath..";/root/skynet/lualib/?.so"
require("libobj")
require("name_t")
json = require("json")
local d = {} 
setmetatable(d, _mt)
d.a.b.c= {1,2,}
d.c= 3
d.a.b.c[1] = nil
lxz(d)
local a = name_t.new({1,1,1})
lxz(name_t,libobj)
a.M.b.name = 2
lxz(name_t,libobj)
require("debugger")
a:del()
a = a:get()
lxz(a)

