module("kw_mall", package.seeall)

_mt = { __index = kw_mall }


kwMallId = 0
gsBuffs = {}
shelf = {}
itemPool = {}


function load_from_db()
    local db = dbmng:getOne()
    local info = db.kw_mall:find({})
    while info:hasNext() do
        local m = info:next()
        setmetatable(m, _mt)
        shelf[m._id] = m
        print("kw_mall m.eid= ", m.eid)
        
    end

    init_pool()
    init_shelf()

end

function init_pool()
    for k, v in pairs(resmng.prop_mall_item) do
        local group = itemPool[v.Group] or {}
        local rate = v.Rate or 10
        group[v.ID] = {rate, v.ID}
        itemPool[v.Group] = group
    end
end

function get_shelf_item(group)
    local pool = itemPool[group]
    if pool then
        local item = get_item_id(pool)
        if item then
            pool[item[2]] = nil
            itemPool[group] = pool
            return item[2]
        end
    end
end

function get_item_id(pool)
    local totalRate = 0
    local cur = 0
    for k, v in pairs(pool) do
        totalRate = totalRate + v[1]
    end
    local rate = math.random(1, totalRate)
    for k, v in pairs(pool) do
        cur = cur + v[1]
        if cur >= rate then
            return v
        end
    end
end

function init_shelf()
    for k, v in pairs(resmng.prop_mall_group_kw) do
        if not shelf[v.ID] then
            local itemId = get_shelf_item(v.Group)
            if itemId  then
                local item = {}
                item._id = v.ID
                item.itemId = itemId
                item.point = 0
                item.state = 0
                shelf[v.ID] = item
                mark(item)
            end
        end
    end
end

function load_kw_buff()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = "kwState"})
    if not info then
        info = {_id = "kwState"}
        db.status:insert(info)
    end
    gsBuffs = info.gsBuffs or {}
end

function mark(m)
    local db = dbmng:getOne()
    if not m.marktm then
        m.marktm = gTime
        db.kw_mall:insert(m)
    else
        m.marktm = gTime
        db.kw_mall:update({_id = m._id}, m)
    end
end

function refresh_kw_mall()
    shelf = {}
    init_pool()
    init_shelf()
end

function buy(ply, index)
    local good = shelf[index]
    if good and can_buy(ply ,index) then
        good.state = 1
    end
    table.insert(gsBuffs, good.itemId)
    gPendingSave.status["kwState"].gsBuffs = gsBuffs
    mark(good)
end

function can_buy(ply, index)
    local good = shelf[index]
    if good then
        if good.state == 1 then
            return false
        end
        if ply.officer ~= KING then
            return false
        end
        return true
    end
    return false
end

function can_vote(ply, index)
    if not shelf[index] then 
        return false
    end
    if not tools.can_date(ply.vote_time) then
        return false
    end
    return true
end

function want_buy(ply, index)
    if can_vote(ply, index) then
        ply.vote_time = gTime
        local good = shelf[index]
        if good then
            good.point = good.point + 1
        end
        mark(good)
    end
end

