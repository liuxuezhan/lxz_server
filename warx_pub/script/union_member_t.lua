--玩家军团信息模块
module(..., package.seeall)
tm_cool = 4 *60*60 --捐献冷却时间
function load()
    local db = dbmng:getOne()
    local info = db.union_member:find({})
    while info:hasNext() do
        local data = info:next()
        local p = getPlayer(data._id)
        if p then
            p._union = copyTab(data)
            local union = unionmng.get_union(p:get_uid())
            if union then
                union._members[p.pid] = p
            end
            p._union.buildlv = {}
            for k,v in pairs (data.buildlv or {}) do
                if k~="_n_"  then
                    p._union.buildlv[v.mode] = v
                end
            end
        else
            print("load_union_member, not found player", data._id)
        end
    end
end

function create(ply, uid, rank)
    local data = {
        _id = ply.pid,
        title = "",
        rank = 0,                   --联盟阶级
        credit = 0,
        history = {},               --历史加入的联盟
        donate = 0,                 --可用捐献
        donate_data = {0,0,0,0},    --捐献记录
        techexp_data = {0,0,0,0},   --捐献获得的科技经验记录
        mark = "",                   --联盟标记
        tmJoin = 0,                 --加入联盟的时间
        tmLeave = 0,                --离开联盟的时间
        donate_flag = 0,            --可否捐献
        tmDonate = 0,               --捐献cd
        buildlv = {},               
        god_log = {lv=0,tm=0},       --战神膜拜记录
        tm_mission = 0,               
        cur_item = 0, --已领军团任务奖励
    }
    gPendingSave.union_member[ply.pid] = data 
    ply._union = data
end

function random_donate_cons(ply, idx, flag,type)
    local conf = resmng.prop_union_donate[union_tech_t.get_class(idx)]
    assert(conf, "no conf found")
    
    local cache = ply._union.donate_cache[idx]
    if not cache then
        cache = {}
        cache[resmng.TECH_DONATE_TYPE.PRIMARY] = math.random(2, #conf.Primary)
        cache[resmng.TECH_DONATE_TYPE.MEDIUM] = 0
        cache[resmng.TECH_DONATE_TYPE.SENIOR] = 0
    else
        if type== resmng.TECH_DONATE_TYPE.MEDIUM or type == resmng.TECH_DONATE_TYPE.SENIOR then
            cache[type] = 0 
        end

        if flag then
            cache[resmng.TECH_DONATE_TYPE.PRIMARY] = math.random(1, #conf.Primary)
        else
            cache[resmng.TECH_DONATE_TYPE.PRIMARY] = cache[resmng.TECH_DONATE_TYPE.PRIMARY] 
        end

        if math.random(100) < 25 then
            local r  = math.random(100)
            if r < 60 then
                cache[resmng.TECH_DONATE_TYPE.MEDIUM] = 2 
            else
                cache[resmng.TECH_DONATE_TYPE.MEDIUM] = 1 
            end
        end

        if math.random(100) < 10 then
            local r  = math.random(100)
            if r < 80 then
                cache[resmng.TECH_DONATE_TYPE.SENIOR] = 2 
            else
                cache[resmng.TECH_DONATE_TYPE.SENIOR] = 1 
            end
        end
    end
    
    ply._union.donate_cache[idx] = cache
    gPendingSave.union_member[ply.pid] = ply._union 
end

function get_donate_cache(ply, idx)

    if not ply._union.donate_cache then
        ply._union.donate_cache = {} 
    end

    if not ply._union.donate_cache[idx] then
        random_donate_cons(ply,idx,false)
    end
    return ply._union.donate_cache[idx]
end

function get_donate_flag(ply)
    if (ply._union.tmDonate or 0) <= gTime and ply._union.donate_flag ~= 0 then
        ply._union.donate_flag = 0
        gPendingSave.union_member[ply.pid] = ply._union 
    end
    return ply._union.donate_flag
end

function add_donate(ply, num)
    assert(num > 0)
    ply._union.donate = ply._union.donate + num

    for i = 1, #ply._union.donate_data do
        ply._union.donate_data[i] = ply._union.donate_data[i] + num
    end
    gPendingSave.union_member[ply.pid] = ply._union 
end

function add_techexp(ply, num)
    assert(num > 0)
    for i = 1, #ply._union.techexp_data do
        ply._union.techexp_data[i] = ply._union.techexp_data[i] + num
    end
    ply._union.techexp_data = ply._union.techexp_data
    gPendingSave.union_member[ply.pid] = ply._union 
end

function clear_donate_data(ply, what)
    ply._union.donate_data[what] = 0  
    ply._union.techexp_data[what] = 0
    gPendingSave.union_member[ply.pid] = ply._union 
end

function add_donate_cooldown(ply, tm)
    if ply._union.tmDonate < gTime then
        ply._union.tmDonate = gTime
    end

    ply._union.tmDonate = ply._union.tmDonate + tm
    if (ply._union.tmDonate - gTime) > tm_cool  then
        ply._union.donate_flag = 1
    end
    gPendingSave.union_member[ply.pid] = ply._union 
end

function clear_tmdonate(ply)
    if ply._union.tmDonate > gTime then
        ply._union.CD_doante_num  = ply._union.CD_doante_num or 0  
        local g =  0  
        if ply._union.CD_doante_num < #resmng.CLEAR_DONATE_COST then       
            g = resmng.CLEAR_DONATE_COST[ply._union.CD_doante_num +1]       
        else
            g = resmng.CLEAR_DONATE_COST[#resmng.CLEAR_DONATE_COST]       
        end
         
        if (ply._union.tmDonate - gTime)< tm_cool then
            g = math.floor((ply._union.tmDonate - gTime) /tm_cool*g) 
        end

        if ply:do_dec_res(resmng.DEF_RES_GOLD, g, VALUE_CHANGE_REASON.UNION_DONATE) then 
            ply._union.donate_flag = 0
            ply._union.tmDonate = gTime
            ply._union.CD_doante_num = ply._union.CD_doante_num + 1 
            gPendingSave.union_member[ply.pid] = ply._union 
        end
    end
end

function leave_union(ply)
    ply._union.tmLeave = gTime
    add_history(ply,{
        uid=ply:get_uid(),
        tmJoin = ply._union.tmJoin,
        tmLeave = gTime,
        rank = ply._union.rank,
    })
    ply._union.mark = ""
    ply._union.title = ""
    ply._union.rank = 0
    ply._union.tmJoin = 0
    ply._union.donate_flag = 1
    clear_donate_data(ply,resmng.DONATE_RANKING_TYPE.DAY)
    clear_donate_data(ply,resmng.DONATE_RANKING_TYPE.WEEK)
    clear_donate_data(ply,resmng.DONATE_RANKING_TYPE.UNION)
    gPendingSave.union_member[ply.pid] = ply._union 
end

function add_history(ply, data)
    table.insert(ply._union.history, 1, data)
    local out = #ply._union.history - 20
    for i = 1, out, 1 do
        table.remove(ply._union.history)
    end
    gPendingSave.union_member[ply.pid] = ply._union 
end

