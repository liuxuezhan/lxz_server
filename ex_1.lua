
package.path =package.path..";/root/skynet/lualib/?.lua"
package.cpath =package.cpath..";/root/skynet/lualib/?.so"
require("libobj")
require("name_t")
json = require("json")
local d = {} 
setmetatable(d, _mt)
require("debugger")
d.a.b.c= {1,2,}
d.c= 3
d.a.b.c[1] = nil
lxz(d)
local a = name_t.new({1,1,1})
a.name = 2
lxz(libobj)
a=a:del()
lxz(a)

