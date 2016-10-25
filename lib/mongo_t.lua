local skynet = require "skynet"
local mongo = require "mongo"
local bson = require "bson"

local server_name = ...
_db = {}

function test_insert_without_index(db_name,db)
	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	local ret = db[db_name].testdb:safe_insert({test_key = 1});
end

function test_insert_with_index(db_name,db)

	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	db[db_name].testdb:ensureIndex({test_key = 1}, {unique = true, name = "test_key_index"})

	local ret = db[db_name].testdb:safe_insert({test_key = 1})
    lxz(ret)	

end

function test_find_and_remove(db_name,db)

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


function test_expire_index(db_name,db)
	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	db[db_name].testdb:ensureIndex({test_key = 1}, {unique = true, name = "test_key_index", expireAfterSeconds = 1, })
	db[db_name].testdb:ensureIndex({test_date = 1}, {expireAfterSeconds = 1, })

	local ret = db[db_name].testdb:safe_insert({test_key = 1, test_date = bson.date(os.time())})
	assert(ret and ret.n == 1)

	local ret = db[db_name].testdb:findOne({test_key = 1})
	assert(ret and ret.test_key == 1)

	for i = 1, 1000 do
		skynet.sleep(11);

		local ret = db[db_name].testdb:findOne({test_key = 1})
		if ret == nil then
			return
		end
	end

	assert(false, "test expire index failed");
end

skynet.start(function()

    require "skynet.manager"	-- import skynet.register
    skynet.register(server_name) --注册服务名字便于其他服务调用

    --[[
        local id = "db1"
      local db=mongo.client(g_db[id]) 
       local info = db.warx_5.status:findOne({_id=5})
        test_insert_without_index(id,db)
        test_insert_with_index(id,db)
        test_find_and_remove(id,db)
        test_expire_index(id,db)
        --]]

    skynet.dispatch("lua", function(session, source, id,data,...)
    --lxz(data)
        data = msg_t.unpack(data)
        if not _db[id] then
            g_db[id].host = g_db[id].host or g_host
            _db[id]={fd = mongo.client(g_db[id]) }
        end

        _db[id].list = data
        for tab, v in pairs(data) do
            for k, d in pairs(v) do
                if k ~= "_bak" then
                    _db[id].list[tab][k] = d 
                end
            end
        end
        --global_save(id,_db[id].list)
        save_t.save_mongo(_db[id].list, _db[id].fd,id)

    end)
end)
