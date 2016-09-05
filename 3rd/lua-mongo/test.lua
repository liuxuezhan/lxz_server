mongo = require "mongo"
dofile("preload.lua")

db = mongo.client { host = "192.168.100.12" }

local r = db:runCommand "listDatabases"--返回不全，lua5.3中一样有问题，不是修改引起的
lxz(r)

local c = db.hello.world:find()--返回的id没有解析

while c:hasNext() do
	local r = c:next()
	lxz(r)
end


db.hello.world:insert {['name']='lxz',['age']=10}
db.hello.world:insert {['name']='lxz',['age']=20}
db.hello.world:insert {['name']='lxz',['age']=30}

local c = db.hello.world:find()

while c:hasNext() do
	local r = c:next()
	lxz(r)
--	lxz(mongo.type(r._id))
end



db.hello.world:delete{['age']=10} 

local c = db.hello.world:find()

while c:hasNext() do
	local r = c:next()
	lxz(r)
end


