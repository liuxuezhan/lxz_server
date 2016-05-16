dofile("base.lua")
--dofile("debugger.lua")
require "lib_player"

local p = lib_player.cs_new(111,2222)

lxz(p)
p[1]=3
lxz(p)
