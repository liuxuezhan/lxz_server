local skynet = require "skynet"
local mongo = require "mongo"
local bson = require "bson"

lxz(...)
local db_name,host,port,user,pwd = ...
local conf ={
        host=host,
        port=port,
        username=user,
        password=pwd,
        }
local _d={}
function test_insert_without_index(db)
	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	local ret = db[db_name].testdb:safe_insert({test_key = 1});
	assert(ret and ret.n == 1)

	local ret = db[db_name].testdb:safe_insert({test_key = 1});
	assert(ret and ret.n == 1)
end

function test_insert_with_index(db)

	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	db[db_name].testdb:ensureIndex({test_key = 1}, {unique = true, name = "test_key_index"})

	local ret = db[db_name].testdb:safe_insert({test_key = 1})
	assert(ret and ret.n == 1)

	local ret = db[db_name].testdb:safe_insert({test_key = 1})
	assert(ret and ret.n == 0)
end

function test_find_and_remove(db)

	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	db[db_name].testdb:ensureIndex({test_key = 1}, {unique = true, name = "test_key_index"})

	local ret = db[db_name].testdb:safe_insert({test_key = 1})
	assert(ret and ret.n == 1)

	local ret = db[db_name].testdb:safe_insert({test_key = 2})
	assert(ret and ret.n == 1)

	local ret = db[db_name].testdb:findOne({test_key = 1})

	assert(ret and ret.test_key == 1)

	local ret = db[db_name].testdb:find({test_key = {['$gt'] = 0}}):sort({test_key = -1}):skip(1):limit(1)

 	assert(ret:count() == 2)
 	assert(ret:count(true) == 1)
	if ret:hasNext() then
		ret = ret:next()
	end
	assert(ret and ret.test_key == 1)

	db[db_name].testdb:delete({test_key = 1})
	db[db_name].testdb:delete({test_key = 2})

	local ret = db[db_name].testdb:findOne({test_key = 1})
	assert(ret == nil)
end


function test_expire_index(db)
	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	db[db_name].testdb:ensureIndex({test_key = 1}, {unique = true, name = "test_key_index", expireAfterSeconds = 1, })
	db[db_name].testdb:ensureIndex({test_date = 1}, {expireAfterSeconds = 1, })

	local ret = db[db_name].testdb:safe_insert({test_key = 1, test_date = bson.date(os.time())})
	assert(ret and ret.n == 1)

	local ret = db[db_name].testdb:findOne({test_key = 1})
	assert(ret and ret.test_key == 1)
	lxz(ret)

	for i = 1, 1000 do
		skynet.sleep(11);

		local ret = db[db_name].testdb:findOne({test_key = 1})
		if ret == nil then
			return
		end
	end

	assert(false, "test expire index failed");
end

function save(db)
    for t,v in pairs(_d) do
        lxz(t)
        for id,d in pairs(v) do
            if d.op == "add" or "up" then
                    db[db_name][t]:update({_id=d._id},{["$set"]=d },true)
            elseif d.op == "del" then

                    db[db_name][t]:delete({_id=d._id})
            end
        end
    end
end
skynet.start(function()
    package.path = package.path..";/root/skynet/lib/?.lua"
    lxz(conf)
	local db = mongo.client(conf)
    lxz()
    --[[
    test_insert_without_index(db)
	test_insert_with_index(db)
	test_find_and_remove(db)
	test_expire_index(db)
   -- db.union:update({_id=self._id}, {["$addToSet"]={log=log}}) 
   --]]

    require "skynet.manager"	-- import skynet.register
    skynet.register(db_name) --注册服务名字便于其他服务调用

    skynet.dispatch("lua", function(session, source, t,data,...)
        local json = require "json"
        data = json.decode(data)
        if not _d[t] then _d[t]={} end
        if not _d[t][data._id] then _d[t][data._id]={} end
        _d[t][data._id]=data
        save(db)
    end)
end)
