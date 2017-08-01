module("dbmng", package.seeall)

idxMap = idxMap or {}
sckMap = sckMap or {}
num = num or 0
pending = pending or {}

--function conn_new(self, sock, db, tips)
function conn_new(self, host, port, dbname, user, pwd, mechanism, sock, db, tips)
    local t = {host=host, port=port, dbname=dbname, user=user, pwd=pwd, mechanism=mechanism, sock=sock, db=db, status="ok", pending=nil, tips=tips}

    if user and pwd then
        t.need_auth = true
        t.authed = self:_authentication(db, user, pwd, mechanism)
        if not t.authed then
            return
        end
    end

    self.sckMap[ sock ] = t
    self.num = self.num + 1
    if not tips then
        table.insert(self.idxMap, t)
    end

    gConns[ sock ].state = 1

    if #self.idxMap > 0 then
        while tabNum(dbmng.pending) > 0 do
            local co = table.remove(dbmng.pending, 1)
            coroutine.resume(co)
        end
    end
end

function conn_close(self, sock)
    WARN("############  dbmng:conn_close, sock=%d", sock)
    for k, v in pairs(self.idxMap) do
        if v.sock == sock then
            table.remove(self.idxMap, k)
            self.sckMap[ sock ] = nil
            self.num = self.num - 1
            conn.toMongo(v.host, v.port, v.dbname, v.user, v.pwd, v.mechanism, v.tips, true)
            return
        end
    end
    local v = self.sckMap[ sock ]
    if v then
        self.sckMap[ sock ] = nil
        conn.toMongo(v.host, v.port, v.dbname, v.user, v.pwd, v.mechanism, v.tips, true)
    end
end

function getOne(self, policy)
    if #self.idxMap < 1 then
        local co = coroutine.running()
        table.insert(dbmng.pending, co)
        coro_mark( co, "waitdb" )
        coroutine.yield("waitdb")
    end
    policy = policy or math.random(64)
    local idx = (policy % #self.idxMap) + 1
    local t = self.idxMap[ idx ]
    return t.db
end

function tryOne(self, policy)
    local count = #self.idxMap
    if count < 1 then return false end
    policy = policy or math.random(64)
    local idx = (policy % count) + 1
    local t = self.idxMap[ idx ]
    return t.db
end

function getByTips(self, tips)
    for _, t in pairs(self.sckMap) do
        if t.tips == tips then return t.db end
    end
end

function getGlobal(self)
    return getByTips(self, "Global")
end

local function db_index_compare_key(key_1, key_2)
    for k, v in pairs(key_1) do
        if key_2[k] ~= v then
            return false
        end
    end

    for k, v in pairs(key_2) do
        if key_1[k] ~= v then
            return false
        end
    end

    return true
end

-- index名字一经确定，不要改变，因为是按照名字来进行比较的
-- 对于key相同的索引，重复创建是成功的，但是name不会发生变化
-- 所以改变index名，会造成每次启动服务器时都去执行一次createIndex，虽然理论上不会带来性能影响
--index_info = {
--    -- player表，name字段
--    ["player"] = {
--        ["player_name_idx"] = {name = 1},
--    }
--}
function index_update(self, index_info, is_global)
    local db = is_global and dbmng:getGlobal() or dbmng:getOne()
    for tab_name, indexes in pairs(index_info) do
        local tab_info = db:runCommand("listCollections", 1, "filter", {name=tab_name})
        dumpTab(tab_info, string.format("listCollections-%s", tab_name), nil, true)
        if tab_info.ok == 1 and tab_info.cursor and tab_info.cursor.firstBatch then
            local tab = tab_info.cursor.firstBatch[1]
            if nil == tab then
                -- 此时还没有table需要创建
                local create_info = db:runCommand("create", tab_name)
                dumpTab(create_info, string.format("create collection-%s", tab_name), nil, true)
                if create_info.ok ~= 1 then
                    ERROR("zhoujy_error: unknown create_info.ok=%s", create_info.ok)
                end
            end
        else
            ERROR("zhoujy_error: unknown info.ok=%s", tab_info.ok)
        end

        local info = db:runCommand("listIndexes", tab_name)
        dumpTab(info, string.format("listIndexes-%s", tab_name), nil, true)
        if info.ok == 1 then
            if info.cursor and info.cursor.firstBatch then
                local db_indexes = info.cursor.firstBatch
                local update_indexes = {}
                local drop_indexes = {}
                for index_name, index_key in pairs(indexes) do
                    local need_update = true
                    for i, one_db_index in ipairs(db_indexes) do
                        if one_db_index.name == index_name then
                            -- 查看key是否一致
                            need_update = not db_index_compare_key(one_db_index.key, index_key)
                            if need_update then
                                drop_indexes[#drop_indexes + 1] = one_db_index.name
                            end
                            break
                        end
                    end

                    if need_update then
                        update_indexes[#update_indexes + 1] = {
                            key=index_key,
                            name=index_name,
                        }
                        WARN("zhoujy_warning: want to update index, tab=%s, index_name=%s", tab_name, index_name)
                        dumpTab(index_key, "index_key", nil, true)
                    end
                end

                if #update_indexes > 0 then
                    for _, drop_index_name in ipairs(drop_indexes) do
                        local drop_info = db:runCommand("dropIndexes", tab_name, "index", drop_index_name)
                        dumpTab(drop_info, "drop_index_info", nil, true)
                    end

                    local create_info = db:runCommand("createIndexes", tab_name, "indexes", update_indexes)
                    dumpTab(create_info, "create_index_info", nil, true)
                    if create_info.ok ~= 1 then
                        ERROR("zhoujy_error: create index failed!")
                    end
                end
            else
                ERROR("zhoujy_error: unknown info structure!")
            end
        else
            ERROR("zhoujy_error: unknown info.ok=%s", info.ok)
        end
    end
end

function _authentication(self, db, username, passwd, mechanism)
    if mechanism == "SCRAM-SHA-1" then
        return self:_authentication_sha1(db, username, passwd)
    elseif mechanism == "MONGODB-CR" then
        return self:_authentication_cr(db, username, passwd)
    else
        FATAL("unsupport MongoDB mechanism!")
        return false
    end
end

function _authentication_sha1(self, db, user, pwd)
    local out_buf = ""
    local auth_message = ""

    local client_nonce = string.format("%u%u%u", math.random(0x7fffffff), math.random(0x7fffffff), math.random(0x7fffffff))
    client_nonce = c_encode_base64(client_nonce)

    out_buf = out_buf.."n,,n="

    local format_user = string.gsub(user, "=", "=3D")
    format_user = string.gsub(format_user, ",", "=2C")
    out_buf = out_buf..format_user..",r="..client_nonce
    auth_message = auth_message..string.sub(out_buf, 4, -1)..","
    
    -- step 1
    local payload = c_encode_base64(out_buf)
    local info = db:runCommand("saslStart", 1, "mechanism", "SCRAM-SHA-1", "payload", payload)
    --local info = db:runCommand("saslStart", 1, "mechanism", "SCRAM-SHA-1", "payload", payload, "autoAuthorize", 1)
    dumpTab(info, "saslStart", nil, true)
    if info.ok ~= 1 then
        FATAL("zhoujy_fatal: DB SCRAM-SHA-1 step 1 auth failed!")
        return false
    end

    -- step 2
    local conversationId = info.conversationId
    local server_payload = c_decode_base64(info.payload)
    local hashed_password = c_md5(string.format("%s:mongo:%s", user, pwd))
    auth_message = auth_message..server_payload..","
    local server_r, server_s, server_i = string.match(server_payload, "r=(.+),s=(.+),i=(.+)")
    out_buf = "c=biws,r="..server_r
    auth_message = auth_message..out_buf
    out_buf = out_buf..",p="
    local decode_salt = c_decode_base64(server_s)
    local iter = tonumber(server_i)
    -- clac salt_password
    local MONGOC_SCRAM_HASH_SIZE = 20
    local start_key = decode_salt.."\0\0\0\1"
    local salt_password = c_crypto_hmac_sha1(hashed_password, start_key)
    local intermediate_digest = string.sub(salt_password, 1, MONGOC_SCRAM_HASH_SIZE)
    local char_array = {}
    for i = 2, iter do
        intermediate_digest = c_crypto_hmac_sha1(hashed_password, intermediate_digest)
        char_array = {}
        for k = 1, MONGOC_SCRAM_HASH_SIZE do
            char_array[#char_array+1] = string.byte(salt_password, k) ~ string.byte(intermediate_digest, k)
        end
        salt_password = string.char(unpack(char_array))
    end
    -- clac client proof
    local client_key = c_crypto_hmac_sha1(salt_password, "Client Key")
    local stored_key = c_crypto_sha1(client_key)
    local client_signature = c_crypto_hmac_sha1(stored_key, auth_message)
    char_array = {}
    for k = 1, MONGOC_SCRAM_HASH_SIZE do
        char_array[#char_array+1] = string.byte(client_key, k) ~ string.byte(client_signature, k)
    end
    local client_proof = string.char(unpack(char_array))
    out_buf = out_buf..c_encode_base64(client_proof)
    payload = c_encode_base64(out_buf)
    info = db:runCommand("saslContinue", 1, "conversationId", conversationId, "payload", payload)
    dumpTab(info, "saslContinue-step2", nil, true)
    if info.ok ~= 1 then
        FATAL("zhoujy_fatal: DB SCRAM-SHA-1 step 2 auth failed!")
        return false
    end

    -- step 3
    conversationId = info.conversationId
    server_payload = c_decode_base64(info.payload)
    local server_e = string.match(server_payload, "e=(.+)")
    local server_v = string.match(server_payload, "v=(.+)")
    if server_e or server_v == nil then
        FATAL("zhoujy_fatal: DB SCRAM-SHA-1 step 3 auth failed!")
        return false
    end
    local server_key = c_crypto_hmac_sha1(salt_password, "Server Key")
    local server_signature = c_crypto_hmac_sha1(server_key, auth_message)
    local encode_server_sign = c_encode_base64(server_signature)
    if encode_server_sign ~= server_v then
        FATAL("zhoujy_fatal: DB SCRAM-SHA-1 step 3 auth failed! server vertify error!")
        return false
    end
    info = db:runCommand("saslContinue", 1, "conversationId", conversationId, "payload", "")
    dumpTab(info, "saslContinue-step3", nil, true)
    if info.ok ~= 1 or info.done ~= true then
        FATAL("zhoujy_fatal: DB SCRAM-SHA-1 step 3 auth failed!")
        return false
    end

    WARN("zhoujy_log: mongo SCRAM-SHA-1 auth successfull!")
    return true
end

function _authentication_cr(self, db, username, passwd)
    local nonce_info = db:runCommand("getnonce", 1)
    if nonce_info.ok == 1 then
        local nonce = nonce_info.nonce
        local digest = string.format("%s:mongo:%s", username, passwd)
        digest = c_md5(digest)
        digest = c_md5(string.format("%s%s%s", nonce, username, digest))
        local auth_info = db:runCommand("authenticate", 1, "user", username, "key", digest, "nonce", nonce, "mechanism", "MONGODB-CR")
        if auth_info.ok == 1 then
            WARN("zhoujy_log: mongo MONGODB-CR auth successfull!")
        else
            dumpTab(auth_info, "auth_info", nil, true)
            FATAL("zhoujy_fatal: mongo auth failed!")
            return false
        end
    else
        dumpTab(nonce_info, "nonce_info", nil, true)
        FATAL("zhoujy_fatal: get nonce failed!")
        return false
    end
    return true
end
