
package.path =package.path..";/root/skynet/lualib/?.lua"
local mod = require("myobj")
local name = require("name_t")
require("debugger")
json = require("json")
local a = name.new(1,1,1)
lxz(a,mod)
a.name = 2
lxz(a,mod)
lxz(1)
