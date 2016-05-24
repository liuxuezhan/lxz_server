module(..., package.seeall)
_id= 1000--当前最大id
_d= {}--数据
function load(db_conf,...)
    lxz(db_conf)
    local mongo = require "mongo"
	local db = mongo.client(db_conf)

    local info = db[db_conf.name].ply:find({})
    while info:hasNext() do
        local v = info:next()
        _d[v._id]=v
        if _id  < v._id then
            _id = v._id
        end
    end
end

function first(name,...)
    _id = _id + 1
    _d[_id]={_id=_id,name=name,}
    return {{},{"ply",_d[_id]}}
end

function dispath(id,type,...)
    local ret 
    if type == "login" then
        lxz(...)
        ret = first(...)
    end
    return ret
end
