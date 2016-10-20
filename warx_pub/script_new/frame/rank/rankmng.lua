module("rankmng")
_allranks = _allranks or {}

-- defines = {
--      size = nil or size,
--      field = {"member", "field_1", "-rev_field_2", ...} or {1, 2, "field", -3, ...}
--      ample = nil or function(score_table) end,
-- }
-- field: 第一个值为pk值, 后面的都为score值，按顺序进行排序，支持字符串或者正数key,不支持非正数key
--        默认从小到大排序，加负号后从大到小排序

_defines = _defines or {}

function add(rank)
    if not _allranks[rank.mode] then _allranks[rank.mode] = {} end
    _allranks[rank.mode][rank.param] = rank
    LOG("[rankmng] add, mode:%s, param:%s", rank.mode, rank.param)
end

function create(mode, param)
    local def = _defines[mode]
    if not def then 
        WARN("[rankmng] create, no define, mode:%s, param:%s", mode, param)
        return 
    end

    if has(mode, param) then
        WARN("[rankmng] create, duplicate, mode:%s, param:%s", mode, param)
        return get(mode, param)
    end
    
    local obj = scorerank_t.new(mode, param, def.size or -1, def.ample)
    if not obj:init_zset(unpack(def.field)) then return end

    add(obj)

    return obj
end

function restore()
    local db = dbmng:getOne()
    local info = db.rank:find({})
    while info:hasNext() do
        local data = info:next()
        local def = _defines[data.mode]
        if not def then
            WARN("[rankmng] restore, no define, mode:%s, id:%s", data.mode, data._id)
        else
            local obj = create(data.mode, data.param)

            for k, v in pairs(data.tbl or {}) do
                if not v._del then obj:add(v) end
            end

            obj:save_all()

            LOG("[rankmng] restore, success, mode:%s, param:%s", data.mode, data.param)
        end
    end
end

function get(mode, param)
    param = param or 0
    if not (_allranks[mode] and _allranks[mode][param]) then 
        WARN("[rankmng] get, not found, mode:%s, param:%s", mode, param)
        return 
    end
    return _allranks[mode][param]
end

function easy_get(mode, param)
    if not has(mode, param) then create(mode, param or 0) end
    return get(mode, param)
end

function has(mode, param)
    param = param or 0
    if not (_allranks[mode] and _allranks[mode][param]) then
        return false
    end
    return true
end

function destory(mode, param)
    if _allranks[mode] and _allranks[mode][param] then
        _allranks[mode][param]:destory()
        _allranks[mode][param] = nil
        LOG("[rankmng] destory, mode:%s, param:%s", mode, param)
    end
end
