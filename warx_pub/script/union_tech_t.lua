
-- 军团科技模块
module(..., package.seeall)

tm_cool = 4 *60*60 --捐献冷却时间

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
    if not conf then return end

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
        if union then union._tech[data.idx] = data end
    end
end

function clear(uid)--删除军团时清除数据
    local union = unionmng.get_union(uid)
    for _,v in pairs(union._tech) do
        gPendingDelete.union_tech[ v._id ] = 1
    end
end

function get_class(idx)
    return math.floor(idx / 1000)
end

function get_mode(idx)
    return idx % 1000
end

function add_exp(data, num)
    data.exp = data.exp + num
	gPendingSave.union_tech[data._id].exp = data.exp
end

function remote_add_exp(union, map_id, id, tech_idx, num)
    local tech = union:get_tech(tech_idx)
    if nil == tech then
        return
    end
    add_exp(tech, num)
    return tech
end

function is_exp_full(data)
    local conf = resmng.get_conf("prop_union_tech",data.id+1)
    if conf then
        if data.exp >= conf.Exp * conf.Star then return true
        else return end
    end
end

function get_lv(data)
    local conf = resmng.prop_union_tech[data.id]
    assert(conf, "conf not found")
    return conf.Lv
end

function get_donate_cache(ply, idx)
    if not ply._union.donate_cache then ply._union.donate_cache = {} end

    if not ply._union.donate_cache[idx] then
        random_donate_cons(ply,idx,false)
    end
    return ply._union.donate_cache[idx]
end

function random_donate_cons(ply, idx, flag, mode)
    local conf = resmng.prop_union_donate[union_tech_t.get_class(idx)]
    if not conf then  return end

    local chg = false

    local cache = ply._union.donate_cache[idx]
    if not cache then
        cache = {}
        cache[resmng.TECH_DONATE_TYPE.PRIMARY] = math.random(1, #conf.Primary)
        cache[resmng.TECH_DONATE_TYPE.MEDIUM] = 0
        cache[resmng.TECH_DONATE_TYPE.SENIOR] = 0
        chg = true

    else
        if mode == resmng.TECH_DONATE_TYPE.MEDIUM or mode == resmng.TECH_DONATE_TYPE.SENIOR then 
            cache[mode] = 0 
            chg = true
        end
        if flag then 
            cache[resmng.TECH_DONATE_TYPE.PRIMARY] = math.random(1, #conf.Primary) 
            chg = true
        end
         
        if math.random(100) < 25 then
            chg = true
            local r  = math.random(100)
            if r < 60 then cache[resmng.TECH_DONATE_TYPE.MEDIUM] = 2
            else cache[resmng.TECH_DONATE_TYPE.MEDIUM] = 1 end
        end

        if math.random(100) < 10 then
            chg = true
            local r  = math.random(100)
            if r < 80 then cache[resmng.TECH_DONATE_TYPE.SENIOR] = 2
            else cache[resmng.TECH_DONATE_TYPE.SENIOR] = 1 end
        end
    end

    if chg then
        ply._union.donate_cache[idx] = cache
        gPendingSave.union_member[ply.pid].donate_cache = ply._union.donate_cache
    end
end



function add_donate_cooldown(ply, tm)
    if ply._union.tmDonate < gTime then ply._union.tmDonate = gTime end

    ply._union.tmDonate = ply._union.tmDonate + tm
    gPendingSave.union_member[ply.pid].tmDonate = ply._union.tmDonate

    if (ply._union.tmDonate - gTime) > tm_cool  then 
        ply._union.donate_flag = 1 
        gPendingSave.union_member[ply.pid].donate_flag = 1
    end
end

function clear_tmdonate(ply)
    if ply._union.tmDonate > gTime then
        ply._union.CD_donate_num  = ply._union.CD_donate_num or 0
        if can_date(ply._union.CD_doante_tm,gTime)  then ply._union.CD_doante_tm  = gTime end

        local g =  0
        if ply._union.CD_donate_num < #resmng.CLEAR_DONATE_COST then
            g = resmng.CLEAR_DONATE_COST[ply._union.CD_donate_num +1]
        else g = resmng.CLEAR_DONATE_COST[#resmng.CLEAR_DONATE_COST] end

        if (ply._union.tmDonate - gTime)< tm_cool then
            g = math.floor((ply._union.tmDonate - gTime) /tm_cool*g)
        end

        if ply:do_dec_res(resmng.DEF_RES_GOLD, g, VALUE_CHANGE_REASON.UNION_DONATE) then
            ply._union.donate_flag = 0
            ply._union.tmDonate = gTime
            ply._union.CD_donate_num = ply._union.CD_donate_num + 1
            gPendingSave.union_member[ply.pid] = ply._union
        end
    end
end


function donate(self, idx, mode)

    local union = unionmng.get_union(self:get_uid())
    if not union then ack(self, "union_donate", resmng.E_NO_UNION) return end

    local tech = union:get_tech(idx)
    if not tech then ack(self, "union_donate", resmng.E_FAIL) return end

    if union_member_t.get_donate_flag(self) == 1 then ack(self, "union_donate", resmng.E_TIMEOUT) return end 

    local donate = get_donate_cache(self,idx)
    if donate[mode] == 0 then ack(self, "union_donate", resmng.E_FAIL) return end

    if not union:can_donate(idx) then ack(self, "union_donate", resmng.E_DISALLOWED) return end

    local cost = nil
    local reward = nil
    local conf = resmng.get_conf("prop_union_donate",get_class(tech.idx))
    if not conf then ack(self, "union_donate", resmng.E_FAIL) return end

    if mode == resmng.TECH_DONATE_TYPE.PRIMARY then
        cost = conf.Primary[donate[mode]]
        reward = conf.Pincome
    elseif mode == resmng.TECH_DONATE_TYPE.MEDIUM then
        if donate[mode] == 1 then cost = conf.Primary[donate[resmng.TECH_DONATE_TYPE.PRIMARY]]
        elseif donate[mode] == 2 then cost = conf.Medium
        end
        reward = conf.Mincome
    elseif mode == resmng.TECH_DONATE_TYPE.SENIOR then
        if donate[mode] == 1 then cost = conf.Primary[donate[resmng.TECH_DONATE_TYPE.PRIMARY]]
        elseif donate[mode] == 2 then cost = conf.Senior
        end
        reward = conf.Sincome
    end

    if not cost or not reward then ack(self, "union_donate", resmng.E_FAIL) return end

    if not self:do_dec_res(cost[1], cost[2], VALUE_CHANGE_REASON.UNION_DONATE) then return end

    self:add_donate(reward[1], VALUE_CHANGE_REASON.REASON_UNION_DONATE)
    union_member_t.add_donate_rank(self,reward[3],reward[1],1)
    union_mission.ok(self,UNION_MISSION_CLASS.DONATE,1)

    local c = resmng.get_conf("prop_union_tech", tech.id + 1)
    if not c then return end
    local full = math.floor(tech.exp/c.Exp)
    if union.map_id then
        local ret, t = remote_func(union.map_id, "remote_add_exp", {"union_tech", union.uid, tech.idx, reward[3]})
        if t then
            tech = t
        end
    else
        add_exp(tech,reward[3])
    end

    union.donate_rank = {}
    add_donate_cooldown(self,conf.TmAdd)

    if full ~= math.floor(tech.exp/c.Exp) then random_donate_cons(self, idx, true, mode)
    else random_donate_cons(self, idx, false, mode) end

    return true
end

function upgrade(union, idx)
    local tech = union:get_tech(idx)
    if not tech or not union_tech_t.is_exp_full(tech) then return resmng.E_FAIL end

    local next_conf = resmng.get_conf("prop_union_tech",tech.id + 1)
    if not next_conf then return resmng.E_MAX_LV end

    if tech.tmOver ~= 0 then return resmng.E_FAIL end

    local tm = next_conf.TmLevelUp
    tech.tmStart = gTime
    tech.tmOver = gTime + tm
    tech.tmSn = timer.new("uniontech", tm, union.uid, idx)
    gPendingSave.union_tech[tech._id] = tech

    union:notifyall(resmng.UNION_EVENT.TECH, resmng.UNION_MODE.UPDATE, { idx=tech.idx,id=tech.id,tmStart=tech.tmStart, tmOver=tech.tmOver })

    return resmng.E_OK
end

function remote_upgrade(union, map_id, id, tech_idx)
    local ret = upgrade(union, tech_idx)
    return {ret}
end

function up_ok(u, tsn, idx)
    local tech = u:get_tech(idx)
    if not tech then return end

    local next_conf = resmng.get_conf("prop_union_tech",tech.id + 1)
    if not next_conf then return end

    tech.id = next_conf.ID
    tech.exp = tech.exp - next_conf.Exp * next_conf.Star
    tech.tmSn = 0
    tech.tmStart = 0
    tech.tmOver = 0
    u:ef_init()
    gPendingSave.union_tech[tech._id] = tech
    u:notifyall(resmng.UNION_EVENT.TECH, resmng.UNION_MODE.ADD, { idx=tech.idx,id=tech.id,exp=tech.exp,tmOver=tech.tmOver,tmStart=tech.tmStart })
    u:add_log(resmng.UNION_EVENT.TECH, resmng.UNION_MODE.ADD, { id=tech.id})
    --世界事件
    world_event.process_world_event(WORLD_EVENT_ACTION.UNION_TECH_NUM, next_conf.ID)
end

