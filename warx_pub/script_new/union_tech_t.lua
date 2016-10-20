
-- 军团科技模块
module(..., package.seeall)

function init(self)
end

function get_conf(class, mode, lv)
    for _, v in pairs(resmng.prop_union_tech) do
        if v.Class == class and v.Mode == mode and v.Lv == lv then
            return v
        end
    end
    return nil
end

function create(idx, uid)
    local conf = get_conf(get_class(idx), get_mode(idx), 0)
    assert(conf, "conf not found")
    local idx = conf.Idx
    local data = {
        _id = string.format("%s_%s", uid, idx),
        idx = idx,
        uid = uid,
        id = conf.ID,
        exp = 0,
		tmStart = 0,
        tmOver = 0,
        tmSn = 0,
    }
	gPendingSave.union_tech[data._id] = data
    return data
end

function load()
    local db = dbmng:getOne()
    local info = db.union_tech:find({})
    while info:hasNext() do
        local data = info:next()
        local union = unionmng.get_union(data.uid)
        if union then
            union._tech[data.idx] = data
        end
    end
end

function clear(uid)--删除军团时清除数据
    local union = unionmng.get_union(uid)
    for _,v in pairs(union._tech) do
        dbmng:getOne().union_tech:delete({_id=v._id})
    end
end

function get_class(idx)
    assert(idx, debug.stack())
    return math.floor(idx / 1000)
end

function get_mode(idx)
    return idx % 1000
end

function add_exp(data, num)
    data.exp = data.exp + num
	gPendingSave.union_tech[data._id] = data
end

function is_exp_full(data)
    local conf = resmng.get_conf("prop_union_tech",data.id+1)
    if conf then
        if data.exp >= conf.Exp * conf.Star then
            return true
        else
            return false
        end
    end
    return false
end

function get_lv(data)
    local conf = resmng.prop_union_tech[data.id]
    assert(conf, "conf not found")
    return conf.Lv
end
