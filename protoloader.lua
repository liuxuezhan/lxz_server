-- module proto as examples/proto.lua
package.path = "./examples/?.lua;" .. package.path

local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local proto = require "proto"

skynet.start(function()
    sprotoloader.save(proto.c2s, 1)  --客户端到服务器的协议
    sprotoloader.save(proto.s2c, 2)  --服务器到客户端的协议
    -- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
