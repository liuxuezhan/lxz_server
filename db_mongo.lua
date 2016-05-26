local skynet = require "skynet"
local mongo = require "mongo"
local bson = require "bson"
local json = require "json"

local server_name = ...
local conf = _list.db[server_name] 
db = {}

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


function check_save(db,data, frame)
    local info = db:runCommand("getLastError")
    if info.ok then
        local code = info.code
        for tab, doc in pairs(data) do
            local cache = doc.__cache
            local dels = {}
            for id, chgs in pairs(cache) do
                if chgs._n_ == frame then
                    --print("ack", id, frame, gFrame)
                    table.insert(dels, id)
                    if code then lxz(chgs, "maybe error") end
                elseif chgs._n_ < frame - 10 then
                    chgs._n_ = nil
                    doc[ id ] = chgs
                    print("retry", id, frame, gFrame)
                    table.insert(dels, id)
                end
            end
            if #dels > 0 then
                for _, v in pairs(dels) do
                    cache[ v ] = nil
                end
            end
        end

        if info.code then
            lxz(info, "check_save")
        end
    end
end

function global_save(id,data)
    local gFrame = (gFrame or 0) + 1
    db = db[id].fd
    local db_name = id 
    if db then
        local update = false
        for tab, doc in pairs(data) do
            local cache = doc.__cache
            for id, chgs in pairs(doc) do
                if chgs ~= cache then
                    if not chgs._a_ then
                        db[db_name][tab]:update({_id=id}, {["$set"] = chgs }, true) 
                        if tab ~= "status" then print("update", tab, id) end
                    else
                        if chgs._a_ == 0 then
                            print("delete", tab, id)
                            db[db_name][ tab ]:delete({_id=id})
                        else
                            print("insert", tab, id)
                            chgs._a_ = nil
                            db[db_name][ tab ]:update({_id=id}, chgs, true)
                            chgs._a_ = 1
                        end
                    end
                    update = true
                    chgs._n_ = gFrame
                    doc[ id ] = nil
                    cache[ id ] = chgs
                end
            end
        end

        if update then check_save(db, data,gFrame) end
    end
end

skynet.start(function()

    require "skynet.manager"	-- import skynet.register
    skynet.register(server_name) --注册服务名字便于其他服务调用

    skynet.dispatch("lua", function(session, source, id,data,...)
        data = json.decode(data)
        lxz(id,_conf.db)
        if not db[id] then
            db[id]={fd = mongo.client(conf[id]),list={data} }
        else
            table.insert(db[id].list,data)
        end

        for _, v in pairs(db[id].list) do
            global_save(id,v)
        end
        --[[
        test_insert_without_index(db)
        test_insert_with_index(db)
        test_find_and_remove(db)
        test_expire_index(db)
        -- db.union:update({_id=self._id}, {["$addToSet"]={log=log}}) 
   --]]
    end)
end)
