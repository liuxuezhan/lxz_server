--local bson = require "bson"
--local socket = require "mongo.socket"
--local socket = require "socket"
local socket = socket
--local driver = require "mongo.driver"
local driver = mongo_driver
local rawget = rawget
local assert = assert

local bson_encode = bson.encode
local bson_encode_order = bson.encode_order
local bson_decode = bson.decode
local bson_id = bson.objectid
local empty_bson = bson_encode {}

local mongo = {}
mongo.null = assert(bson.null)
mongo.maxkey = assert(bson.maxkey)
mongo.minkey = assert(bson.minkey)
mongo.type = assert(bson.type)

mongo.querySn = mongo.querySn or 0


local mongo_cursor = {}
local cursor_meta = {
	__index = mongo_cursor,
}

local mongo_client = {}

local client_meta = {
	__index = function(self, key)
		return rawget(mongo_client, key) or self:getDB(key)
	end,
	__tostring = function (self)
		local port_string
		if self.port then
			port_string = ":" .. tostring(self.port)
		else
			port_string = ""
		end

		return "[mongo client : " .. self.host .. port_string .."]"
	end,
	__gc = function(self)
		self:disconnect()
	end
}

local mongo_db = {}

local db_meta = {
	__index = function (self, key)
		return rawget(mongo_db, key) or self:getCollection(key)
	end,
	__tostring = function (self)
		return "[mongo db : " .. self.name .. "]"
	end
}

local mongo_collection = {}
local collection_meta = {
	__index = function(self, key)
		return rawget(mongo_collection, key) or self:getCollection(key)
	end ,
	__tostring = function (self)
		return "[mongo collection : " .. self.full_name .. "]"
	end
}

function mongo.client( obj )
	obj.port = obj.port or 27017
	obj.__id = 0
	obj.__sock = assert(socket.open(obj.host, obj.port),"Connect failed")
	return setmetatable(obj, client_meta)
end

function mongo.client2( host, port, sock, is_global )
    local obj = {}
    obj.host = host
	obj.port = obj.port or 27017
	obj.__id = 0
	obj.__sock = sock
    obj.__is_global = is_global or false
	return setmetatable(obj, client_meta)
end


function mongo_client:getDB(dbname)
	local db = {
		connection = self,
		name = dbname,
		full_name = dbname,
		database = false,
		__cmd = dbname .. "." .. "$cmd",
	}

	db.database = db

	return setmetatable(db, db_meta)
end

function mongo_client:disconnect()
	if rawget(self, "__sock") then
		socket.close(self.__sock)
		self.__sock = nil
	end
end

function mongo_client:genId()
	--local id = self.__id + 1
	--self.__id = id
	--return id

    mongo.querySn = mongo.querySn + 1
    return mongo.querySn
end

function mongo_client:runCommand(...)
	if not self.admin then
		self.admin = self:getDB "admin"
	end
	return self.admin:runCommand(...)
end

-- Mark: this funciton is change

--local function get_reply(sock, result)
--	local length = driver.length(socket.read(sock, 4))
--	local reply = socket.read(sock, length)
--	return reply, driver.reply(reply, result)
--end

-- extra = {
--     cmd = "find",
--     cmd_data = {
--         query = query_bson,
--         selector = selector_bson,
--         doc = document
--     },
--     is_global = true or false,
-- }
--
-- extra = {
--     cmd = "findOne",
--     cmd_data = {
--         query = query_bson,
--         selector = selector_bson,
--     },
--     is_global = true or false,
-- }
--
-- extra = {
--     cmd = "runCommand",
--     cmd_data = {
--         bson_cmd = bson_cmd
--     },
--     is_global = true or false,
-- }
--
-- extra = {
--     cmd = "runCommand2",
--     cmd_data = {
--         same with param
--     },
--     is_global = true or false,
-- }
function get_reply(request_id, sock, extra)
    --dbmng:pending(sock)
    --local  data, succ, reply_id, doc, cursor = putCoroPend("db", sock, result)
    --dbmng:release(sock)
    --return data, succ, reply_id, doc, cursor

    --LOG("get_reply, request_id = %d", request_id)
    local  data, succ, reply_id, doc, cursor = putCoroPend("db", request_id, extra)
    --INFO( "RESUME, get_reply, request_id=%s, reply_id=%s, succ=%s", request_id, reply_id, succ )
    return data, succ, reply_id, doc, cursor
end

function mongo.recvReply(sock)
    --local reply = pullPkg()
    --local co, result = getCoroPend("db", sock)
    --if co then
    --    local succ, reply_id, doc, cursor = driver.reply(reply, result)
    --    coroutine.resume(co, reply, succ, reply_id, doc, cursor)
    --else
    --    local succ, reply_id, doc, cursor = driver.reply(reply)
    --    LOG("not found db coro")
    --    dumpTab( bson_decode(doc))
    --end

    local reply = pullPkg()
    local code, id = getReplyID(reply)

    if id then
        --LOG("get_reply, reply_id = %d", id)
        local co, extra = getCoroPend("db", id)

        local node = gCoroMark[ co ]
        if node then node.nest = (node.nest or 0) + 1 end

        local doc = nil
        if extra and extra.cmd == "find" then
            doc = extra.cmd_data.doc
        end
        local succ, reply_id, doc, cursor = driver.reply(reply, doc)
        if co then
            --INFO( "recvReply, succ=%s, reply_id=%s", succ, reply_id )
            coroutine.resume(co, reply, succ, reply_id, doc, cursor)
        else
            --INFO( "recvReply, succ=%s, reply_id=%s, not found co", succ, reply_id )
            -- mongo reconnect后已经从gCoroPend中删除了co，此时co可能为空
        end
    else
        WARN("error, recvReply")
    end
end

function mongo.do_recv_data( reply )
    local code, id = getReplyID(reply)
    if id then
        local co, extra = getCoroPend("db", id)
        local node = gCoroMark[ co ]
        if node then
            node.nest = (node.nest or 0) + 1
        else
            WARN( "not mark this coro %s", co )
        end

        local doc = nil
        if extra and extra.cmd == "find" then
            doc = extra.cmd_data.doc
        end
        local succ, reply_id, doc, cursor = driver.reply(reply, doc)
        if co then
            coroutine.resume(co, reply, succ, reply_id, doc, cursor)
        end
    else
        WARN("error, recvReply")
    end
end


function mongo_db:runCommand(cmd,cmd_v,...)
	local request_id = self.connection:genId()
	local sock = self.connection.__sock
	local bson_cmd
	if not cmd_v then
		bson_cmd = bson_encode_order(cmd,1)
	else
		bson_cmd = bson_encode_order(cmd,cmd_v,...)
	end
	local pack = driver.query(request_id, 0, self.__cmd, 0, 1, bson_cmd)
	-- todo: check send
	socket.write(sock, pack)
    local extra = {
        cmd = "runCommand",
        cmd_data = {
            bson_cmd = bson_cmd,
        },
        is_global = self.connection.__is_global,
    }
	local _, succ, reply_id, doc = get_reply(request_id, sock, extra)
    --LOG("runCommand, get_reply")
	assert(request_id == reply_id, "Reply from mongod error")
	-- todo: check succ
    local info = bson_decode( doc )

    return info
end


function mongo_db:runCommand2(param)
	local request_id = self.connection:genId()
	local sock = self.connection.__sock
	local pack = driver.query(request_id, 0, self.__cmd, 0, 1, param.bson_cmd)
	-- todo: check send
    socket.write(sock, pack)

    local extra = {
        cmd = "runCommand2",
        cmd_data = param,
        is_global = self.connection.__is_global,
    }

	local _, succ, reply_id, doc = get_reply(request_id, sock, extra)
    --LOG("runCommand, get_reply")
	assert(request_id == reply_id, "Reply from mongod error")
	-- todo: check succ
	return bson_decode(doc)
end

function mongo_db:getCollection(collection)
	local col = {
		connection = self.connection,
		name = collection,
		full_name = self.full_name .. "." .. collection,
		database = self.database,
	}
	self[collection] = setmetatable(col, collection_meta)
	return col
end

mongo_collection.getCollection = mongo_db.getCollection

function mongo_collection:insert(doc)
    if not doc then
        return
    end
	if doc._id == nil then
		doc._id = bson.objectid()
	end
	local sock = self.connection.__sock
	local pack = driver.insert(0, self.full_name, bson_encode(doc))
	socket.write(sock, pack)
end


function mongo_collection:insert_sync(doc)
    if not doc then
        return
    end
	if doc._id == nil then
		doc._id = bson.objectid()
	end
	local sock = self.connection.__sock
	local pack = driver.insert(0, self.full_name, bson_encode(doc))
	socket.write(sock, pack)

    local info = self.database:runCommand("getLastError")
    dumpTab(doc, "insert doc")
    dumpTab(info, "insert res")
end


function mongo_collection:batch_insert(docs)
	for i=1,#docs do
		if docs[i]._id == nil then
			docs[i]._id = bson.objectid()
		end
		docs[i] = bson_encode(docs[i])
	end
	local sock = self.connection.__sock
	local pack = driver.insert(0, self.full_name, docs)
	-- todo: check send
	socket.write(sock, pack)
end


function mongo_collection:update(selector,update,upsert,multi)
	local flags = (upsert and 1 or 0) + (multi and 2 or 0)
	local sock = self.connection.__sock
	local pack = driver.update(self.full_name, flags, bson_encode(selector), bson_encode(update))
	-- todo: check send
	socket.write(sock, pack)
end


function mongo_collection:delete(selector, single)
	local sock = self.connection.__sock
	local pack = driver.delete(self.full_name, single, bson_encode(selector))
	-- todo: check send
	socket.write(sock, pack)
end

function mongo_collection:findOne(query, selector)
	local request_id = self.connection:genId()
	local sock = self.connection.__sock
    local query_bson = query and bson_encode(query) or empty_bson
    local selector_bson = selector and bson_encode(selector)
	local pack = driver.query(request_id, 0, self.full_name, 0, 1, query_bson, selector_bson)

	-- todo: check send
	socket.write(sock, pack)

    local extra = {
        cmd = "findOne",
        cmd_data = {
            query = query_bson,
            selector = selector_bson,
        },
        is_global = self.connection.__is_global,
    }
	local _, succ, reply_id, doc = get_reply(request_id, sock, extra)
	assert(request_id == reply_id, "Reply from mongod error")
	-- todo: check succ
	return bson_decode(doc)
end

function mongo_collection:find(query, selector)
	return setmetatable( {
		__collection = self,
		__query = query and bson_encode(query) or empty_bson,
		__selector = selector and bson_encode(selector),
		__ptr = nil,
		__data = nil,
		__cursor = nil,
		__document = {},
		__flags = 0,
        __skip = 0,
        __limit = 0,
	} , cursor_meta)
end

function mongo_cursor:hasNext()
	if self.__ptr == nil then
		if self.__document == nil then
			return false
		end
		local conn = self.__collection.connection
		local request_id = conn:genId()
		local sock = conn.__sock
		local pack
		if self.__data == nil then
			pack = driver.query(request_id, self.__flags, self.__collection.full_name, self.__skip, self.__limit, self.__query, self.__selector)
		else
			if self.__cursor then
				pack = driver.more(request_id, self.__collection.full_name, self.__limit, self.__cursor)
			else
				-- no more
				self.__document = nil
				self.__data = nil
				return false
			end
		end

		--todo: check send
		socket.write(sock, pack)

        local extra = {
            cmd = "find",
            cmd_data = {
                query = self.__query,
                selector = self.__selector,
                doc = self.__document,
            },
            is_global = conn.__is_global,
        }
		local data, succ, reply_id, doc, cursor = get_reply(request_id, sock, extra)

        if request_id ~= reply_id then
            WARN( "[MONGO], error, request_id=%s, reply_id=%s", request_id, reply_id )
            return false
        end

		if succ then
			if doc then
				self.__data = data
				self.__ptr = 1
				self.__cursor = cursor
				return true
			else
				self.__document = nil
				self.__data = nil
				self.__cursor = nil
				return false
			end
		else
			self.__document = nil
			self.__data = nil
			self.__cursor = nil
			if doc then
				local err = bson_decode(doc)
				error(err["$err"])
			else
				error("Reply from mongod error")
			end
		end
    end

	return true
end

function mongo_cursor:next()
	if self.__ptr == nil then
		error "Call hasNext first"
	end
	local r = bson_decode(self.__document[self.__ptr])
	self.__ptr = self.__ptr + 1
	if self.__ptr > #self.__document then
		self.__ptr = nil
	end

	return r
end

function mongo_cursor:close()
	-- todo: warning hasNext after close
	if self.__cursor then
		local sock = self.__collection.connection.__sock
		local pack = driver.kill(self.__cursor)
		-- todo: check send
		socket.write(sock, pack)
	end
end

return mongo
