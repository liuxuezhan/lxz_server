module(..., package.seeall)
_id= 1000--当前最大id
_d= {}--数据
function load(name,host,port,user,pwd ,...)
    local mongo = require "mongo"
    lxz()
	local db = mongo.client({ host=host, port=port, username=user, password=pwd, })
    lxz()

    local info = db[name].ply:find({})
    while info:hasNext() do
        local v = info:next()
        _d[v._id]=v
        if _id  < v._id then
            _id = v._id
        end
    end
end

function first(name,...)
lxz(...)
    _id = _id + 1
    _d[_id]={_id=_id,name=name,op="add"}
    lxz(_d)
    return {{},{"ply",_d[_id]}}
end

function dispath(id,type,...)
lxz(type)
    local ret 
    if type == "login" then
        ret = first(...)
    end
    lxz(ret)
    return ret
end
