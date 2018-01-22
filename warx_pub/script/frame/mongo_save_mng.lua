module("mongo_save_mng", package.seeall)

CMD_TYPE_UPDATE = 1
CMD_TYPE_DELETE = 2

SAVE_STATE_NONE = 0
SAVE_STATE_SENT = 1

_switch = _switch or (config.Game == "actx")-- 总开关， 不支持动态修改
--_switch = true
_running_coro_cnt = _running_coro_cnt or 0  -- 记录当前正在进行数据库写操作的协程数量
_coro_pool = _coro_pool or {}               -- 用于执行数据库写操作的协程
_save_data = _save_data or {}               -- 用于缓存数据库写操作数据的table
_statistics = _statistics or {game_db = {}, global_db = {}}             -- 用于记录统计数据
_ack_tick = _ack_tick or {game_db = {}, global_db = {}}                 -- 用于记录每次数据库请求的发起时间，用于判断ack超时
_ack_window_data = _ack_window_data or {game_db = {}, global_db = {}}   -- 用于数据库写请求基于帧数和ack的流控的数据

COMMON_WRITE_CONCERN = {w=1, wtimeout=5000} -- 故意不使用j=true的选项，3.2后默认50ms刷一次，参考：https://docs.mongodb.com/manual/core/journaling/

if ACK_WINDOW_SIZE == nil then
    if config.Game == "actx" then           -- act机器人压力测试途中，大并发登录时，这里会成为瓶颈，所以放开到100
        ACK_WINDOW_SIZE = 100
    else
        ACK_WINDOW_SIZE = 2                         -- 用于设置同时向mongo发起几帧的写数据请求，最小为1
    end
end

--_save_data = {
--    game_db = {
--        --when ack arrived, if success, del cache_data, otherwise move to err_data and log error.
--        raw_save = {
--            array = {
--                [1] = {
--                    __state = SAVE_STATE_NONE
--                    __frame = 102
--                    [1] = bson_cmd
--                }
--            }
--        }
--        by_id_save = {
--            array = {
--                [1] = {
--                    __state = SAVE_STATE_NONE
--                    __frame = 101
--                    ["player"] = {
--                        -- this is for gPendingSave
--                        [30018] = {...}
--                        __cmd_data = {
--                            [1] = bson_cmd
--                        },
--                    }
--                }
--            }
--        }
--        error_data = {
--            [1] = {
--                is_raw_save = false,
--                frame_id = 101,
--                tab = "player",
--                cmd = {...},
--                info = {...},
--            },
--            [2] = {
--                is_raw_save = true,
--                frame_id = 102,
--                cmd = {...},
--                info = {...},
--            }
--            ...
--        },
--    }
--    global_db = {
--          same with game_db
--    }
--}
--
--_ack_window_data = {
--      game_db = {
--          [1] = {frame = 101, remain_ack = 3},
--          [2] = {frame = 105, remain_ack = 5},
--          [3] = {frame = 120, remain_ack = 1},
--      },
--      global_db = {
--          same with game_db
--      },
--}
----------------------------------------------------------------------------------------------
__mt_save_rec = {
    __index = function(self, rec_id)
        local t = {}
        self[rec_id] = t
        return t
    end
}
__mt_save_coll = {
    __index = function(self, tab)
        local t = {
            __cmd_data = {},
        }
        setmetatable(t, __mt_save_rec)
        self[tab] = t
        return t
    end
}
__mt_save_frame = {
    __index = function(self, frame_id)
        local t = {__state = SAVE_STATE_NONE, __frame = frame_id}
        setmetatable(t, __mt_save_coll)
        table.insert(self.array, t)
        self[frame_id] = t
        return t
    end
}
function init()
    _save_data = {
        game_db = {
            raw_save = setmetatable({array = {}}, __mt_save_frame),
            by_id_save = setmetatable({array = {}}, __mt_save_frame),
            error_data = {},
        },
        global_db = {
            raw_save = setmetatable({array = {}}, __mt_save_frame),
            by_id_save = setmetatable({array = {}}, __mt_save_frame),
            error_data = {},
        }
    }
end

function get_collection_table(tab, is_global)
    local db_tab = _save_data.game_db
    if is_global then
        db_tab = _save_data.global_db
    end
    return db_tab.by_id_save[gFrame][tab]
end

function put_bson_cmd(frame, tab, bson_cmd, is_raw, is_global)
    local db_tab = _save_data.game_db
    if is_global then
        db_tab = _save_data.global_db
    end

    if is_raw then
        table.insert(db_tab.raw_save[frame], bson_cmd)
    else
        table.insert(db_tab.by_id_save[frame][tab].__cmd_data, bson_cmd)
    end
end

function loop_array_to_write(save_tab, is_raw_save, is_global)
    --dumpTab(save_tab, "loop_array_to_write")
    local save_array = save_tab.array

    while true do
        local frame_data = save_array[1]
        if frame_data == nil then
            break
        end
        if not need_send_write_op(is_global) then
            if #save_array > 200 and #save_array % 50 == 0 then
                WARN("zhoujy_warning: save request in queue, frame_cnt=%d", #save_array)
            end
            LOG("zhoujy_log: mongo write limit by ack_window_size, frame_cnt=%d", #save_array)
            break
        end

        table.remove(save_array, 1)
        save_tab[frame_data.__frame] = nil
        -- 为了保证一帧内的raw_save有序，需要使用ipairs，如果有元表会死循环
        setmetatable(frame_data, nil)

        if frame_data.__state == SAVE_STATE_NONE then
            local cmd_cnt = 0
            local param = {
                frame = frame_data.__frame,
                is_raw_save = is_raw_save,
                is_global = is_global,
            }
            if is_raw_save then
                for i, one_cmd in ipairs(frame_data) do
                    param.bson_cmd = one_cmd
                    gen_coro_runcommand(param)
                    cmd_cnt = cmd_cnt + 1
                end
            else
                for k, one_tab in pairs(frame_data) do
                    if k ~= "__state" and k ~= "__frame" then
                        param.tab = k
                        for i, one_cmd in ipairs(one_tab.__cmd_data) do
                            param.bson_cmd = one_cmd
                            gen_coro_runcommand(param)
                            cmd_cnt = cmd_cnt + 1
                        end
                    end
                end
            end
            frame_data.__state = SAVE_STATE_SENT
            if cmd_cnt > 0 then
                cache_send_write_op(is_global, frame_data.__frame, cmd_cnt)
            end
        else
            ERROR("zhoujy_error: mongo_save.loop_array_to_write state=%d should not be here.", frame_data.__state)
        end
    end
end

function mongo_error_stack(err)
    local stacks = debug.traceback(err, 2)
    WARN(stacks)
    if perfmon and perfmon.on_exception then
        perfmon.on_exception()
    end
end

function build_bson_cmd(tab, docs, is_raw, is_delete, is_global)
    local update_docs = nil
    local del_docs = nil
    if is_delete then
        del_docs = docs
    else
        update_docs = docs
    end

    local catch_an_error = false

    if update_docs and #update_docs > 0 then
        local db_tab = _statistics.game_db
        if is_global then
            db_tab = _statistics.global_db
        end
        db_tab[tab] = db_tab[tab] or {up_cnt = 0, max_up_doc = 0}
        local stat_tab = db_tab[tab]
        stat_tab.up_cnt = stat_tab.up_cnt + 1
        if #update_docs > stat_tab.max_up_doc then
            stat_tab.max_up_doc = #update_docs
        end

        local call_ret, bson_cmd = xpcall(bson.encode_order, mongo_error_stack, "update", tab, "updates", update_docs, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN)
        --local bson_cmd = bson.encode_order("update", tab, "updates", update_docs, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN)
        if call_ret then
            put_bson_cmd(gFrame-1, tab, bson_cmd, is_raw, is_global)
        else
            ERROR("zhoujy_error: encode_order catch an error, tab=%s", tab)
            catch_an_error = true
        end

        -- TODO: mongo document said wtimeout will active only when w great than 1. keep notice.
        if #update_docs > 500 or catch_an_error then
            if not catch_an_error then WARN("zhoujy_warning: monogo save update %d once, should optimize! may be use raw sql", #update_docs) end
            local part_docs = {}
            table.move(update_docs, 1, 20, 1, part_docs)
            dumpTab(part_docs, "part of update_docs", nil, true)
        end
    end

    if del_docs and #del_docs > 0 then
        local call_ret, bson_cmd = xpcall(bson.encode_order, mongo_error_stack, "delete", tab, "deletes", del_docs, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN)
        if call_ret then
            put_bson_cmd(gFrame-1, tab, bson_cmd, is_raw, is_global)
        else
            ERROR("zhoujy_error: encode_order catch an error, tab=%s", tab)
            catch_an_error = true
        end

        if #del_docs > 500 or catch_an_error then
            if not catch_an_error then WARN("zhoujy_warning: monogo save delete %d once, should optimize! may be use raw sql", #del_docs) end
            local part_docs = {}
            table.move(del_docs, 1, 20, 1, part_docs)
            dumpTab(part_docs, "part of del_docs", nil, true)
        end
    end
end

function by_pid_save_update(pendingSave, is_global)
    -- 修改为严格时序性后需要放在后面
    local db = nil
    if is_global then
        db = dbmng:getGlobal()
    else
        db = dbmng:tryOne(1)
    end
    if not db then
        WARN("zhoujy_warning: mongo_save_update no db, is_global=%s", is_global)
        return
    end

    if not is_db_alive(is_global) then
        WARN("zhoujy_warning: trigger mongo reconnect by timeout. is_global=%s", is_global)
        local mongo_cli = db.connection
        dbmng:conn_close(mongo_cli.__sock)
        gConns[mongo_cli.__sock] = nil
        mongo_cli:disconnect()

        return
    end

    local cbs = gUpdateCallBack
    --为了避免在遍历gPendingSave的途中去调用on_check_pending接口，防止开发者错误的在on_check_pending中去进行了数据库操作
    local cb_map = {}       --key为函数，value为table(key为id, value为chgs)

    for tab, doc in pairs(pendingSave) do
        local cb = nil
        local old_ids = {}
        local update_docs = {}
        local del_docs = {}
        --dumpTab(doc, "by_sid_save_update doc")
        for id, chgs in pairs(doc) do
            if id ~= "__cmd_data" then
                if chgs._id ~= nil and chgs._id ~= id then
                    old_ids[chgs._id] = chgs
                end
                rawset(chgs, "_id", id)

                if not chgs._a_ then
                    if tab ~= "todo" then
                        LOG( "[DB], update, %s, %s", tab, tostring(id) )
                    end
                    update_docs[#update_docs+1] = {
                        q = {_id = id},
                        u = {["$set"] = chgs},
                        upsert = true,
                        multi = false,
                    }
                else
                    if chgs._a_ == 0 then
                        if tab ~= "todo" then
                            LOG( "[DB], delete, %s, %s", tab, tostring(id) )
                        end
                        del_docs[#del_docs+1] = {
                            q = {_id = id},
                            limit = 1,
                        }
                    else
                        if tab ~= "todo" then
                            LOG( "[DB], create, %s, %s", tab, tostring(id) )
                        end
                        rawset(chgs, "_a_", nil)
                        update_docs[#update_docs+1] = {
                            q = {_id = id},
                            u = chgs,
                            upsert = true,
                            multi = false,
                        }
                    end
                end

                if not is_global then
                    if cb == nil then
                        cb = cbs[ tab ]
                        if cb == nil then
                            if _G[ tab ] and type( _G[ tab ] ) == "table" then
                                if _G[ tab ].on_check_pending then
                                    cb = _G[ tab ].on_check_pending
                                    if cb == nil then cb = false end
                                end
                            end
                            cbs[ tab ] = cb
                        end
                    end

                    if cb then
                        cb_map[cb] = cb_map[cb] or {}
                        cb_map[cb][id] = chgs
                    end
                end

                if #update_docs >= 1000 then
                    build_bson_cmd(tab, update_docs, false, false, is_global)
                    update_docs = {}
                end
                if #del_docs >= 1000 then
                    build_bson_cmd(tab, del_docs, false, true, is_global)
                    del_docs = {}
                end
            end
        end

        build_bson_cmd(tab, update_docs, false, false, is_global)
        build_bson_cmd(tab, del_docs, false, true, is_global)

        for old_id, chgs in pairs(old_ids) do
            rawset(chgs, "_id", old_id)
        end
    end

    if not is_global then
        -- on_check_pending统一在外部调用
        for cb, params in pairs(cb_map) do
            for id, chgs in pairs(params) do
                cb(db, id, chgs)
            end
        end
    end

    -- 故意放在on_check_pending调用之后
    for tab, doc in pairs(pendingSave) do
        pendingSave[tab] = nil
    end

    -- write db in order
    local db_tab = _save_data.game_db
    if is_global then
        db_tab = _save_data.global_db
    end

    if #db_tab.raw_save.array > 0 then
        loop_array_to_write(db_tab.raw_save, true, is_global)
    end
    if #db_tab.by_id_save.array > 0 then
        loop_array_to_write(db_tab.by_id_save, false, is_global)
    end
end

--[[
--query: search condition, eg: {_id = 1}
--modifier: modifier, eg: {[$set] = chgs}
--upsert: true means create if not exist
--multi: true means execute this update for multi records
--is_global: is global db or not
--]]--
function raw_update(tab, query, modifier, upsert, multi, is_global)
    if type(tab) ~= "string" or type(query) ~= "table" or type(modifier) ~= "table" or type(upsert) ~= "boolean" or type(multi) ~= "boolean" or type(is_global) ~= "boolean" then
        ERROR("zhoujy_error: invalid param for raw_update. tab=%s, query=%s, modifier=%s, upsert=%s, multi=%s, is_global=%s", tab, query, modifier, upsert, multi, is_global)
        return
    end

    local update_docs = {}
    update_docs[1] = {
        q = query,
        u = modifier,
        upsert = upsert,
        multi = multi,
    }

    build_bson_cmd(tab, update_docs, true, false, is_global)
end

function raw_batch_update(tab, update_docs, is_global)
    if type(tab) ~= "string" or type(update_docs) ~= "table" or type(is_global) ~= "boolean" then
        ERROR("zhoujy_error: invalid param for raw_batch_update. tab=%s, update_docs=%s, is_global=%s", tab, update_docs, is_global)
        return
    end
    if #update_docs <= 0 then
        return
    end

    local tmp_docs = {}
    for i, v in ipairs(update_docs) do
        if type(v.q) ~= "table" or type(v.u) ~= "table" or type(v.upsert) ~= "boolean" or type(v.multi) ~= "boolean" then
            ERROR("zhoujy_error: invalid param for raw_batch_update, tab=%s, v.q=%s, v.u=%s, v.upsert=%s, v.multi=%s", tab, v.q, v.u, v.upsert, v.multi)
            return
        end
        tmp_docs[#tmp_docs+1] = v
        if #tmp_docs >= 1000 then
            build_bson_cmd(tab, tmp_docs, true, false, is_global)
            tmp_docs = {}
        end
    end

    build_bson_cmd(tab, tmp_docs, true, false, is_global)
end

function raw_del(tab, query, limit, is_global)
    if type(tab) ~= "string" or type(query) ~= "table" or type(limit) ~= "number" or limit < 0 or type(is_global) ~= "boolean" then
        ERROR("zhoujy_error: invalid param for raw_del. tab=%s, query=%s, limit=%s, is_global=%s", tab, query, limit, is_global)
        return
    end

    local del_docs = {}
    del_docs[1] = {
        q = query,
        limit = limit,
    }

    build_bson_cmd(tab, del_docs, true, true, is_global)
end

function do_threadDB()
    while true do
        local param = coroutine.yield()
        local is_global = param.is_global
        local db = dbmng:tryOne(1)
        if is_global then
            db = dbmng:getGlobal()
        end
        if db then
            local frame_id = param.frame
            local is_raw_save = param.is_raw_save
            local bson_cmd = param.bson_cmd

            local db_tab = _ack_tick.game_db
            if is_global then
                db_tab = _ack_tick.global_db
            end
            local co = coroutine.running()
            db_tab[tostring(co)] = gTime
            local info = db:runCommand2(param)
            -- recvReply时统一放到了gCoroBad中，保留此引用会造成co对象泄漏
            -- gCoroBad[co] = nil
            db_tab[tostring(co)] = nil
            on_send_write_ack(is_global, frame_id)

            local is_error = false
            if info.ok ~= nil and info.ok == 1 then
                if info.errmsg or info.writeErrors or info.writeConcernError then
                    is_error = true
                else
                    --dumpTab(info, "save ok info")
                end
            else
                ERROR("zhoujy_error: do_threadDB unknown ok=%s, code=%s, errmsg=%s", info.ok, info.code, info.errmsg)
                is_error = true
            end

            if is_error then
                local err_db_tab = _save_data.game_db
                if is_global then
                    err_db_tab = _save_data.global_db
                end

                ERROR("zhoujy_error: do_threadDB catch a error! error_cnt=%d support write cmd only!", #err_db_tab.error_data + 1)
                local one_error = {
                    is_raw_save = is_raw_save,
                    frame_id = frame_id,
                    cmd = bson.decode(bson_cmd),
                    info = info,
                }
                if not is_raw_save then
                    one_error.tab = param.tab
                end

                dumpTab(info, "do_threadDB info", nil, true)
                local short_err_cmd = one_error.cmd
                local docs = nil

                if one_error.cmd.updates and #one_error.cmd.updates > 20 then
                    docs = one_error.cmd.updates
                elseif one_error.cmd.deletes and #one_error.cmd.deletes > 20 then
                    docs = one_error.cmd.deletes
                end

                if docs ~= nil then
                    short_err_cmd = {}
                    table.move(docs, 1, 20, 1, short_err_cmd)
                end
                dumpTab(short_err_cmd, "sql cmd", nil, true)

                table.insert(err_db_tab.error_data, one_error)
            end
        else
            ERROR("zhoujy_error: do_threadDB can not get db. this is impossible!")
        end
        put_coro_to_pool()
    end
end

function threadDB()
    if _ENV then
        xpcall(do_threadDB, STACK)
    else
        do_threadDB()
    end
end

-- param = {frame, is_raw_save, bson_cmd}
function gen_coro_runcommand(param)
    local co = nil
    if #_coro_pool > 0 then
        co = table.remove(_coro_pool)
    else
        co = coroutine.create(threadDB)
        coroutine.resume(co)
    end
    _running_coro_cnt = _running_coro_cnt + 1
    if _running_coro_cnt >= 100 and (_running_coro_cnt % 20 == 0) then
        ERROR("zhoujy_error: running db write coroutine num=%d, must be something wrong!", _running_coro_cnt)
    end
    coroutine.resume(co, param)
end

function put_coro_to_pool()
    local co = coroutine.running()
    if #_coro_pool < 50 then
        table.insert(_coro_pool, co)
    end
    _running_coro_cnt = _running_coro_cnt - 1
end

function dump_error()
    dumpTab(_save_data.game_db.error_data, "game_db error")
    dumpTab(_save_data.global_db.error_data, "global_db error")
end

function is_remain_db_action(is_global)
    local db_tab = _save_data.game_db
    if is_global then
        db_tab = _save_data.global_db
    end
    local by_id_count = #db_tab.by_id_save.array
    local raw_count = #db_tab.raw_save.array

    if by_id_count > 0 or raw_count > 0 then
        -- 还有未发起的数据库请求
        return true
    end

    local ack_tab = _ack_window_data.game_db
    if is_global then
        ack_tab = _ack_window_data.global_db
    end
    -- 全部写请求都已经收到ack了
    return #ack_tab > 0
end

function is_db_alive(is_global)
    local timeout = 30
    if gCompensation then
        timeout = 90
    end

    local db_tab = _ack_tick.game_db
    if is_global then
        db_tab = _ack_tick.global_db
    end

    for k, v in pairs(db_tab) do
        if gTime - v > timeout then
            return false
        end
    end
    return true
end

function loop_decode_bson(save_tab, is_raw_save)
    local save_array = save_tab.array
    for i, frame_data in ipairs(save_array) do
        if is_raw_save then
            for k, one_cmd in pairs(frame_data) do
                if k ~= "__state" and k ~= "__frame" then
                    frame_data[k] = bson.decode(one_cmd)
                end
            end
        else
            for k, one_tab in pairs(frame_data) do
                if k ~= "__state" and k ~= "__frame" then
                    for i, one_cmd in ipairs(one_tab.__cmd_data) do
                        one_tab.__cmd_data[i] = bson.decode(one_cmd)
                    end
                end
            end
        end
    end
end

function dump2file(filename)
    local file,err = io.open( filename, "wb" )
    if err then
        ERROR("zhoujy_error: dump2file filename=%s catch an error:%s", filename, err)
        return
    end

    -- cmsgpack不支持userdata结构, 所以先将bson转换成table再存文件
    loop_decode_bson(_save_data.game_db.raw_save, true)
    loop_decode_bson(_save_data.game_db.by_id_save, false)
    loop_decode_bson(_save_data.global_db.raw_save, true)
    loop_decode_bson(_save_data.global_db.by_id_save, false)

    local pack_str = cmsgpack.pack(_save_data)
    file:write(pack_str)
    file:close()

    -- bson是需要有序的，转了后就不能再转回来了
    _save_data = {}
    init()
end

function cache_send_write_op(is_global, frame, remain_ack)
    if remain_ack <= 0 then
        ERROR("zhoujy_error: this is impossible!, remain_ack=%d", remain_ack)
        return
    end

    local db_tab = _ack_window_data.game_db
    if is_global then
        db_tab = _ack_window_data.global_db
    end

    if #db_tab > 0 then
        local last_ack_data = db_tab[#db_tab]
        if last_ack_data.frame == frame then
            last_ack_data.remain_ack = last_ack_data.remain_ack + remain_ack
            return
        end
    end

    if #db_tab >= ACK_WINDOW_SIZE then
        ERROR("zhoujy_error: this is impossible!, #db_tab=%d", #db_tab)
    end

    table.insert(db_tab, {frame = frame, remain_ack = remain_ack})
end

function need_send_write_op(is_global)
    local db_tab = _ack_window_data.game_db
    if is_global then
        db_tab = _ack_window_data.global_db
    end
    return #db_tab < ACK_WINDOW_SIZE
end

function on_send_write_ack(is_global, frame)
    local db_tab = _ack_window_data.game_db
    if is_global then
        db_tab = _ack_window_data.global_db
    end

    local ack_data = db_tab[1]
    if ack_data == nil then
        ERROR("zhoujy_error: this is impossible!")
    end
    if ack_data.frame ~= frame or ack_data.remain_ack <= 0 then
        ERROR("zhoujy_error: this is impossible!, cache.frame=%d, ack.frame=%d, remain_ack=%d", ack_data.frame, frame, ack_data.remain_ack)
    else
        ack_data.remain_ack = ack_data.remain_ack - 1
        if ack_data.remain_ack <= 0 then
            table.remove(db_tab, 1)
            LOG("zhoujy_log: one frame ack all back. frame=%d, #db_tab=%d", frame, #db_tab)
        end
    end
end

function log_redo_sql(cmd_data)
    local log_t = {}
    for k, v in pairs(cmd_data) do
        if type(v) == "userdata" then
            log_t[k] = bson.decode(v)
        else
            log_t[k] = v
        end
    end
    dumpTab(log_t, "no back mongo", nil, true)
end

function log_other_sql(extra)
    local cmd_data = extra.cmd_data
    cmd_data.doc = nil
    for k, v in pairs(cmd_data) do
        if type(v) == "userdata" then
            cmd_data[k] = bson.decode(v)
        end
    end
    dumpTab(extra, "no back mongo", nil, true)
end

function on_db_reconnect(is_global)
    if not _switch then return end
    WARN("zhoujy_warning: will handle mongo reconnect, is_global=%s", is_global)
    -- reset _ack_tick
    if is_global then
        _ack_tick.global_db = {}
    else
        _ack_tick.game_db = {}
    end

    -- reset _ack_window_data
    if is_global then
        _ack_window_data.global_db = {}
    else
        _ack_window_data.game_db = {}
    end

    -- release co who pending on db action and restore mongo_save_mng no ack write ops
    local redo_cmd = setmetatable({array = {}}, __mt_save_frame)
    local db_coro_pend = gCoroPend["db"]
    for k, v in pairs(db_coro_pend) do
        if type(v) == "table" then
            local extra = v[2]
            if extra.is_global == is_global then
                if extra.cmd == "runCommand2" then
                    local param = extra.cmd_data
                    table.insert(redo_cmd[param.frame], param)
                    log_redo_sql(param)
                else
                    log_other_sql(extra)
                end
                db_coro_pend[k] = nil
            end
        else
            ERROR("zhoujy_error: this is impossible!")
        end
    end

    if #redo_cmd.array > 0 then
        if #redo_cmd.array > 1 then
            table.sort(redo_cmd.array, function(a, b) return a.__frame > b.__frame end)
        end

        for i, one_frame in ipairs(redo_cmd.array) do
            for k, one_cmd in pairs(one_frame) do
                if k ~= "__state" and k ~= "__frame" then
                    --local param = {
                    --    frame = frame_data.__frame,
                    --    is_raw_save = is_raw_save,
                    --    is_global = is_global,
                    --    bson_cmd = bson_cmd,
                    --    tab = tab,        -- only when is_raw_save is false
                    --}
                    local db_tab = _save_data.game_db
                    if one_cmd.is_global then
                        db_tab = _save_data.global_db
                    end
                    if one_cmd.is_raw_save then
                        db_tab = db_tab.raw_save
                    else
                        db_tab = db_tab.by_id_save
                    end

                    if nil == rawget(db_tab, one_cmd.frame) then
                        WARN("zhoujy_warning: rawset frame request data. frame=%d", one_cmd.frame)

                        local t = {__state = SAVE_STATE_NONE, __frame = one_cmd.frame}
                        setmetatable(t, __mt_save_coll)
                        -- 插在第一位
                        table.insert(db_tab.array, 1, t)
                        rawset(db_tab, one_cmd.frame, t)
                    end

                    put_bson_cmd(one_cmd.frame, one_cmd.tab, one_cmd.bson_cmd, one_cmd.is_raw_save, one_cmd.is_global)
                    WARN("zhoujy_warning: redo mongo save. frame=%d, tab=%s", one_cmd.frame, one_cmd.tab)
                end
            end
        end
    end

    if not is_global and config.Game == "actx" then
        xpcall(playermng.on_db_reconnect, STACK)
    end
    WARN("zhoujy_warning: handle mongo reconnect done, is_global=%s", is_global)
end

if _save_data.game_db== nil then
    init()
end
