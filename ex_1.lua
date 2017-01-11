
package.path =package.path..";/root/skynet/lualib/?.lua"
require("libobj")
require("name_t")
require("debugger")
json = require("json")
local a = name_t.new(1,1,1)
a.name = 2
lxz(libobj)
a=a:del()
lxz(a)

