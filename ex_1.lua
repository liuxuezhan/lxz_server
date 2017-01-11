
package.path =package.path..";/root/skynet/lualib/?.lua"
local mod = require("myobj")
name_t = require("name_t")
require("debugger")
json = require("json")
local a = name_t.new(1,1,1)
a.name = 2
lxz(mod)
a=a:del()
lxz(a)

