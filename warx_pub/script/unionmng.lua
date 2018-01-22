-- Hx@2015-11-30 : 军团管理
module("unionmng", package.seeall)

_us = _us or {}
_us2 = _us2 or {}

function add_union(u)
    _us[u.uid] = u
end

function add_union2(u)
    _us2[u.uid] = u
end

function get_union(uid)
    local u = _us[uid]
    return u  or _us2[uid]
end

function rm_union(u)
    u:destory()
    _us[u.uid] = nil
end

function rm_union2(u)
    u:destory()
    _us2[u.uid] = nil
end

function get_all(flag)
    flag = flag or 0
    local us = {}
    if 0 == get_bit(flag, 1) then
        for k, u in pairs(_us) do
            us[k] = u
        end
    end
    if 0 == get_bit(flag, 2) then
        for k, u in pairs(_us2) do
            us[k] = u
        end
    end
    return us
end

