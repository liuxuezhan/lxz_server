
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

function get_donate_cache(ply, idx)

    if not ply._union.donate_cache then
        ply._union.donate_cache = {}
    end

    if not ply._union.donate_cache[idx] then
        random_donate_cons(ply,idx,false)
    end
    return ply._union.donate_cache[idx]
end

function random_donate_cons(ply, idx, flag,type)
    local conf = resmng.prop_union_donate[union_tech_t.get_class(idx)]
    if not conf then  return end

    local cache = ply._union.donate_cache[idx]
    if not cache then
        cache = {}
        cache[resmng.TECH_DONATE_TYPE.PRIMARY] = math.random(1, #conf.Primary)
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
        if can_date(ply._union.CD_doante_tm)  then ply._union.CD_doante_tm  = gTime end

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

function add_techexp(ply, num,r)
    if num < 0 then
		WARN("")
		return
	end

	if r== VALUE_CHANGE_REASON.REASON_UNION_DONATE then
		for i = DONATE_RANKING_TYPE.DAY, DONATE_RANKING_TYPE.UNION do
			ply._union.techexp_data[i] = ply._union.techexp_data[i] + num
		end
	elseif r== VALUE_CHANGE_REASON.UNION_BUILDLV then
		for i = DONATE_RANKING_TYPE.DAY_B, DONATE_RANKING_TYPE.UNION_B do
			ply._union.techexp_data[i] = ply._union.techexp_data[i] + num
		end
	end
    ply._union.techexp_data = ply._union.techexp_data
    gPendingSave.union_member[ply.pid] = ply._union
end

function donate(self, idx, type)

    local union = unionmng.get_union(self:get_uid())
    if not union then ack(self, "union_donate", resmng.E_NO_UNION) return end

    local tech = union:get_tech(idx)
    if not tech then ack(self, "union_donate", resmng.E_FAIL) return end

    if union_member_t.get_donate_flag(self) == 1 then ack(self, "union_donate", resmng.E_TIMEOUT) return end 

    local donate = get_donate_cache(self,idx)
    if donate[type] == 0 then ack(self, "union_donate", resmng.E_FAIL) return end

    if not union:can_donate(idx) then ack(self, "union_donate", resmng.E_DISALLOWED) return end

    local cost = nil
    local reward = nil
    local conf = resmng.get_conf("prop_union_donate",get_class(tech.idx))
    if not conf then ack(self, "union_donate", resmng.E_FAIL) return end

    if type == resmng.TECH_DONATE_TYPE.PRIMARY then
        cost = conf.Primary[donate[type]]
        reward = conf.Pincome
    elseif type == resmng.TECH_DONATE_TYPE.MEDIUM then
        if donate[type] == 1 then
            cost = conf.Primary[donate[resmng.TECH_DONATE_TYPE.PRIMARY]]
        elseif donate[type] == 2 then
            cost = conf.Medium
        end
        reward = conf.Mincome
    elseif type == resmng.TECH_DONATE_TYPE.SENIOR then
        if donate[type] == 1 then
            cost = conf.Primary[donate[resmng.TECH_DONATE_TYPE.PRIMARY]]
        elseif donate[type] == 2 then
            cost = conf.Senior
        end
        reward = conf.Sincome
    end
    if not cost or not reward then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    if not self:do_dec_res(cost[1], cost[2], VALUE_CHANGE_REASON.UNION_DONATE) then
        return
    end

    self:add_donate(reward[1], VALUE_CHANGE_REASON.REASON_UNION_DONATE)
    add_techexp(self,reward[3],VALUE_CHANGE_REASON.REASON_UNION_DONATE)
    union_mission.ok(self,UNION_MISSION_CLASS.DONATE,1)

    local c = resmng.get_conf("prop_union_tech", tech.id + 1)
    if not c then return end
    local mode = math.floor(tech.exp/c.Exp)
    add_exp(tech,reward[3])

    union.donate_rank = {}
    add_donate_cooldown(self,conf.TmAdd)

    if mode ~= math.floor(tech.exp/c.Exp) then
        random_donate_cons(self,idx, true,type)
    else
        random_donate_cons(self,idx, false,type)
    end

    return true
end

function upgrade(union, idx)
    local tech = union:get_tech(idx)
    if not tech or not union_tech_t.is_exp_full(tech) then
        return resmng.E_FAIL
    end

    local next_conf = resmng.get_conf("prop_union_tech",tech.id + 1)
    if not next_conf then
        return resmng.E_MAX_LV
    end

    if tech.tmOver ~= 0 then
        return resmng.E_FAIL
    end

    local tm = next_conf.TmLevelUp
    tech.tmStart = gTime
    tech.tmOver = gTime + tm
    tech.tmSn = timer.new("uniontech", tm, union.uid, idx)
    gPendingSave.union_tech[tech._id] = tech

    union:notifyall(resmng.UNION_EVENT.TECH, resmng.UNION_MODE.UPDATE, { idx=tech.idx,id=tech.id,tmStart=tech.tmStart, tmOver=tech.tmOver })

    return resmng.E_OK
end

function up_ok(u, tsn, idx)
    local tech = u:get_tech(idx)
    if not tech then
        WARN("timer got no tech") return
    end

    local next_conf = resmng.get_conf("prop_union_tech",tech.id + 1)
    if not next_conf then
        INFO("没有下一级:"..tech.id+1) 
        return
    end

    tech.id = next_conf.ID
    tech.exp = tech.exp - next_conf.Exp * next_conf.Star
    tech.tmSn = 0
    tech.tmStart = 0
    tech.tmOver = 0
    u:ef_init()
    gPendingSave.union_tech[tech._id] = tech
    u:notifyall(resmng.UNION_EVENT.TECH, resmng.UNION_MODE.ADD, { idx=tech.idx,id=tech.id,exp=tech.exp,tmOver=tech.tmOver,tmStart=tech.tmStart })
end

