module("login_queue", package.seeall)

_login_id = _login_id or 0
-- {
--      sid = xxx,
--      login_id = xxx,
--      enter_time = xxx,
--      inited = false,
--      pack = pack,
-- }
_login_queue = _login_queue or {}       -- 数组
_login_sid_tab = _login_sid_tab or {}   -- key:sid, value:true
_change_cache = _change_cache or {}
_last_update_time = _last_update_time or 0

function _gen_login_id()
    _login_id = _login_id + 1
    return _login_id
end

function _get_time_factor()
    -- seconds for one player waitting
    return config.LoginTimeFactor or 3
end

function _notify_queue_init(node, pos)
    node.inited = true

    local data = {
        login_id = node.login_id,
        pos = pos,
        time_factor = _get_time_factor(),
    }
    INFO("Login queue init! sid=%d, pos=%d", node.sid, pos)
    Rpc:sendToSock(node.sid, "login_in_queue_init", data)
end

function _notify_queue_update(data)
    local sids = {}
    for i, v in ipairs(_login_queue) do
        if v.inited == true then
            table.insert(sids, v.sid)
        end
    end
    if #sids > 0 then
        INFO("Login queue update! send to %d sessions", #sids)
        Rpc:sendToSock(sids, "login_in_queue_update", data)
    end
end

function _remove_from_queue(sid)
    -- remove from queue
    for i, v in ipairs(_login_queue) do
        if v.sid == sid then
            _change_cache[#_change_cache+1] = sid
            _login_sid_tab[sid] = nil
            table.remove(_login_queue, i)
            return
        end
    end
end

function is_in_queue(sid)
    return _login_sid_tab[sid] ~= nil
end

function after_authed(sid, pack)
    if is_in_queue(sid) then
        ERROR("zhoujy_error: already in login queue. sid=%d", sid)
        return
    end
    local node = {
        sid = sid,
        login_id = _gen_login_id(),
        enter_time = gTime,
        inited = false,
        pack = pack,
    }
    _login_sid_tab[sid] = true
    table.insert(_login_queue, node)

    pushHead(_G.GateSid, 0, 21)  -- NET_SET_IN_QUEUE
    pushInt(sid)
    pushInt(gMapID)
    pushOver()
end

function after_break(sid)
    if is_in_queue(sid) then
        _remove_from_queue(sid)
    end
end


function update()
    local max_num = can_handle_login_num() 
    local remove_sids = {}
    for i, v in ipairs(_login_queue) do
        if i < max_num then
            table.insert(remove_sids, v.sid)
            action(player_t.handle_login_from_queue, unpack(v.pack))
            begJob()
        else
            break
        end
    end

    for i, sid in ipairs(remove_sids) do
        _remove_from_queue(sid)
    end

    if _last_update_time == 0 then
        _last_update_time = gTime
    end
    if _last_update_time ~= gTime then
        -- update必须先于init，不然玩家的pos不对
        _notify_queue_update(_change_cache)
        _change_cache = {}

        for i, v in ipairs(_login_queue) do
            if v.enter_time + 1 < gTime and not v.inited then
                _notify_queue_init(v, i)
            end
        end

        _last_update_time = gTime
    end
end
