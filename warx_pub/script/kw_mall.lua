module("kw_mall", package.seeall)

_mt = { __index = kw_mall }


refresh_time = refresh_time or 0
gsBuffs = gsBuffs or {}
gsEf = gsEf or{}
shelf = shelf or {}
itemPool = itemPool or {}
kw_point = kw_point or 0


initDbList = 
{
    "gsBuffs",
    "gsEf",
--    "itemPool",
--    "shelf",
}


function load_from_db()
    --[[local db = dbmng:getOne()
    local info = db.kw_mall:find({})
    while info:hasNext() do
        local m = info:next()
        setmetatable(m, _mt)
        shelf[m._id] = m
        print("kw_mall m.eid= ", m.eid)
        
    end--]]

    init_db_list()
    load_kw_shelf()
    if #shelf == 0 then
        refresh_kw_mall()
    end
end



function init_db_list()
    for k, v in pairs(initDbList) do
        kw_mall[ v ] = init_db(v)
    end
end

function init_db(key)
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = key})
    --dumpTap(info, Key)
    if not info then
        info = {_id = key}
        db.status:insert(info)
    end
    return info[key] or {}
end

function add_buf(bufid, count)
    local node = resmng.prop_buff[ bufid ]
    if node then
        if count < 1 then count = 1 end

        local dels = {}
        if node.Mutex == 1 then  -- 互斥
            local group = node.Group
            for k, v in ipairs(gsBuffs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    table.insert(dels, k)
                end
            end

        elseif node.Mutex == 2 then -- 高级替换低级
            local group = node.Group
            local lv = node.Lv
            for k, v in ipairs(gsBuffs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    if b.Lv > lv then return end
                    table.insert(dels, k)
                end
            end
        end

        if #dels > 0 then
            for i = #dels, 1, -1 do
                table.remove(gsBuffs, dels[ i ]) 
            end
        end

        if node.Value then ef_add(node.Value) end
        local tmOver = gTime + count
        local buf = {bufid, gTime, tmOver}
        table.insert(gsBuffs, buf)
        gPendingSave.status["gsBuffs"].gsBuffs = gsBuffs
        Rpc:gs_buf_ntf({pid = -1, gid = _G.GateSid}, gsBuffs)
        timer.new("globuf", count, bufid, tmOver)
        print(string.format("add_buf, bufid=%d, tmStart=%d, count=%d", bufid, gTime, count))
        return buf
    end
end

function rem_buf(bufid, tmOver)
    for k, v in pairs(gsBuffs) do
        --v = {bufid, tmOver}
        if v[1] == bufid then
            if not tmOver or tmOver == v[3] then
                table.remove(gsBuffs, k)
                local node = resmng.prop_buff[ bufid ]
                if node and node.Value then ef_rem(node.Value) end
                print(string.format("rem_buf,  bufid=%d, tmOver=%d, now=%d", bufid, tmOver or -1, gTime))
                return v[3]
            end
        end
    end
    Rpc:gs_buf_ntf({pid = -1, gid = _G.GateSid}, gsBuffs)
    gPendingSave.status["gsBuffs"].gsBuffs = gsBuffs
end

function rem_all_buf()
    for k, v in pairs(gsBuffs or {}) do
        if k ~= "_id" then
            table.remove(gsBuffs, k)
            local node = resmng.prop_buff[ v[1] ]
            if node and node.Value then ef_rem(node.Value) end
            print(string.format("rem_buf, bufid=%d, now=%d", k,  gTime))
        end
    end
    Rpc:gs_buf_ntf({pid = -1, gid = _G.GateSid}, gsBuffs or {})
    gPendingSave.status["gsBuffs"].gsBuffs = gsBuffs
end

function get_buf(bufid )
    for k, v in pairs(gsBuffs) do
        --v = {bufid, tmStart, tmOver}
        if v[1] == bufid then
            return v
        end
    end
end

function calc_diff(A, B) -- A, original; B, new one
    local C = {}
    for k, v in pairs(A) do
        C[k] = (B[k] or 0) - v
    end
    for k, v in pairs(B) do
        if not A[k] then
            C[k] = B[k]
        end
    end
    return C
end

function ef_chg(A, B) -- A, original; B, new, for upgrade
    local C = calc_diff(A, B)
    ef_add(C)
end

function ef_add(eff, init)
    if not eff then return end
    local res = {}
    for k, v in pairs(eff) do
        if type(v) == "table" then 
            ERROR( "ef_add, type error" )
        else
            gsEf[k] = (gsEf[k] or 0) + v
            res[ k ] = gsEf[k]
            if math.abs(gsEf[k]) <= 0.00001 then gsEf[k] = nil end
            if not init then LOG("ef_add, what=%s, num=%d",  k, v) end
        end
    end
    gPendingSave.status["gsEf"].gsEf = gsEf
    --if not init then Rpc:stateEf(self, res) end
end

function ef_rem(eff)
    if not eff then return end
    local t = gsEf
    local res = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) - v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        LOG("ef_rem, what=%s, num=%d",  k, v)
    end
    gPendingSave.status["gsEf"].gsEf = gsEf
end

function get_num(what, ...) -- VALUE DIRECTLY
    if ... == nil then
        return gsEf[ what ] or 0 
    else
        local v = 0
        for _, t in pairs({...}) do
            v = v + (t[ what ] or 0)
        end
        return v
    end
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
   --             mark(item)
            end
        end
    end
    gPendingSave.status["kwState"].shelf = shelf
end

function add_kw_point(point)
    kw_point = kw_point + point
    gPendingSave.status["kwState"].kw_point = kw_point
end

function do_consume(point)
    kw_point = kw_point - point
    gPendingSave.status["kwState"].kw_point = kw_point
end

function get_kw_point()
    return kw_point or 0
end

function load_kw_shelf()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = "kwState"})
    if not info then
        info = {_id = "kwState"}
        db.status:insert(info)
    end
    shelf = info.shelf or {}
    refresh_time = info.refresh_time or 0
    kw_point = info.kw_point or 0
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
    refresh_time = get_next_time()
    gPendingSave.status["kwState"].refresh_time = refresh_time
end

function buy(ply, index)
    local good = shelf[index]
    if good and can_buy(ply ,index) then
        good.state = 1
    end
    local conf = resmng.prop_mall_item[good.itemId]
    if conf then
        if ply:condCheck(conf.Pay) then
            ply:consume(conf.Pay, 1, VALUE_CHANGE_REASON.KW_MALL_BUY)
            for k, item in pairs(conf.Buy or {}) do
                local itemp = resmng.prop_item[item[2]] or {}
                local num = item[3]
                if itemp.Open == 1 then
                    player_t.use_item_logic[itemp.Action](ply,itemp.ID, num, itemp)
                else
                    ply:add_bonus("mutex_award", conf.Buy, VALUE_CHANGE_REASON.KW_MALL_BUY, 1, true)
                end
            end
        end
    end
    --table.insert(gsBuffs, good.itemId)
    --gPendingSave.status["kwState"].gsBuffs = gsBuffs
    gPendingSave.status["gsBuffs"].gsBuffs = gsBuffs
    gPendingSave.status["kwState"].shelf = shelf
    --mark(good)
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
    if can_date(ply.vote_time) then
        return true
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
        gPendingSave.status["kwState"].shelf = shelf
    end
end

