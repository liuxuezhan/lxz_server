-- Hx@2015-11-30 : 军团管理
module("unionmng", package.seeall)

_us = _us or {}

function add_union(u)
    _us[u.uid] = u
end

function get_union(uid)
    return _us[uid]
end

function rm_union(u)
    u:destory()
    _us[u.uid] = nil
end

function get_all()
    return _us
end
