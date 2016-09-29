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
    return _us[uid] or _us2[uid]
end

function rm_union(u)
    u:destory()
    _us[u.uid] = nil
end

function get_all()
    local us = {}
    for k, u in pairs(_us) do
        us[k] = u
    end
    for k, u in pairs(_us2) do
        us[k] = u
    end
    return us
end
