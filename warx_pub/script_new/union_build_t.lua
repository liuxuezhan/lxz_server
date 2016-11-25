
--------------- 军团建筑模块 -----------------------------------------------------------

module(..., package.seeall)
 _sn = 0--建造时间顺序
local min_hp = 1
function load()
    local db = dbmng:getOne()
    local info = db.union_build:find({})
    while info:hasNext() do
        local data = info:next()
        local u = unionmng.get_union(data.uid)
        if u  and data.state ~= BUILD_STATE.DESTROY then
            u.build[data.idx] = data
            gEtys[ data.eid ] = data
            data.name = ""
            data.holding = 0
            data.culture = data.culture or 1
            etypipe.add(data)
            if _sn < (data.sn or 0 ) then
                _sn = data.sn
            end
        end
    end
end


function create(uid,idx, propid, x, y,name)

    assert(idx and propid and  uid and  x and y)
    local u = unionmng.get_union(uid)
    if not u then return end

    local cc = resmng.get_conf("prop_world_unit",propid)
    if (not cc) or cc.Class ~= BUILD_CLASS.UNION then return end
    --TODO: 地图空位检测
    if c_map_test_pos(x, y, cc.Size) ~= 0 then 
        LOG("军团建筑不在空地")
        return 
    end

    if not u:can_build(propid,x,y) then return end
    local e 
    if idx == 0 then
        idx = #u.build+1
        local _id = string.format("%s_%s", idx, uid)
        _sn = _sn + 1
        e = {
            _id = _id,
            eid = get_eid_uion_building(),
            idx = idx,
            uid = uid,
            alias = u.alias,
            hp = min_hp,
            x = x,
            y = y,
            size = cc.Size,
            propid = propid,
            range = 0,
            state = BUILD_STATE.CREATE,
            sn = _sn,
            val = cc.Count or 0,
            speed = 0,
            build_speed = 0,
            tmStart_b = 0,
            tmStart_g = 0,
            name = name,
            fire_tmStart = 0,
            fire_tmOver = 0,
            fire_speed = 0,
            fire_tmSn = 0,
            tmSn = 0,
        }
        if u.god then
            local c = resmng.get_conf("prop_union_god",u.god.propid)
            if c then
                e.culture =  c.Mode
            end
        end

        save_ety(e)
    else
        e = u.build[idx]
        if not e then return end
        e.eid = get_eid_uion_building()
        _sn = _sn + 1
        e.sn = _sn
        if cc.Hp == e.hp then
            e.state = BUILD_STATE.WAIT
        else
            e.state = BUILD_STATE.CREATE
        end
        if e.hp == 0  or (cc.BuildMode == UNION_CONSTRUCT_TYPE.SUPERRES) then e.hp = min_hp end
        e.x = x
        e.y = y
        e.speed = 0
        e.build_speed = 0
        e.tmStart_b = 0
        e.tmStart_g = 0
        e.name = name
        e.fire_tmStart = 0
        e.fire_tmOver = 0
        e.fire_speed = 0
        e.fire_tmSn = 0
        e.tmSn = 0
        e.my_troop_id = nil
        e.val = cc.Count or 0
        save_ety(e)
        if cc.Hp == e.hp then
            union_build_t.buf_open(e)
        end
    end
    u:add_log(resmng.UNION_EVENT.BUILD_SET, resmng.UNION_MODE.ADD,{propid=e.propid,name=e.name})
end

function remove(e)
    if not e then return end

    local u = unionmng.get_union(e.uid)
    if not u then return end

    if is_union_miracal(e.propid) then
        union_build_t.buf_close(e)
    end
    union_build_t.remove_build(e)

    --拆除奇迹相关建筑
    if is_union_miracal(e.propid) then
        for k, v in pairs(u.build) do
            local cc = resmng.get_conf("prop_world_unit",v.propid)
            if cc and (not is_union_miracal(v.propid)) then
                if not u:can_castle(v.x,v.y,cc.Size/2) then
                    remove_build(v)
                end
            end
        end
    end
end

function remove_build(e)
    local u = unionmng.get_union(e.uid)
    if not u then return end

    local bcc = resmng.get_conf("prop_world_unit",e.propid) or {}
    if not bcc then return false end

    if e.state == BUILD_STATE.CREATE then
        local tr = troop_mng.get_troop(e.my_troop_id)
        if tr then
            for _, v in pairs(tr.arms) do
                local one = tr:split_pid(v.pid)
                local ply = getPlayer(v.pid)
                ply:troop_recall(one._id)
            end
        end
        del(e)
        return
    end

    if is_union_miracal(e.propid) then
        local tr = troop_mng.get_troop(e.my_troop_id)
        if tr then
            for _, v in pairs(tr.arms) do
                local one = tr:split_pid(v.pid)
                if one  then
                    local ply = getPlayer(v.pid)
                    ply:troop_recall(one._id)
                end
            end
        end
        del(e)

    elseif is_union_superres(e.propid) then

        if type(e.my_troop_id)=="table" then
            for k, v in pairs(e.my_troop_id or {} ) do
                local one = troop_mng.get_troop(v)
                if one then
                    local ply = getPlayer(one.owner_pid)
                    ply:troop_recall(one._id)
                end
            end
        end
        del(e)
        u.build[e.idx] = nil
        gPendingDelete.union_buid[e._id] = 0 
    elseif is_union_restore(e.propid) then
        for _, v in pairs(u.build ) do
            local c = resmng.get_conf("prop_world_unit",v.propid)
            if v.eid ~= e.eid and c.Mode == resmng.CLASS_UNION_BUILD_RESTORE and v.state~= BUILD_STATE.DESTORY then--仓库
                del(e)
                return
            end
        end
        restore_del_res(e.uid)--取出资源
        del(e)
        --[[
    elseif bcc.Mode == resmng.CLASS_UNION_BUILD_MARKET then        --市场
        for _, v in pairs(u.build ) do
            local c = resmng.get_conf("prop_world_unit",v.propid)
            if v.eid ~= e.eid  and c.Mode == resmng.CLASS_UNION_BUILD_MARKET and v.state~= BUILD_STATE.DESTORY then--仓库
                del(e)
                return 
            end
        end
        market_del(e)--取出
        del(e)
        --]]
    end
end

function restore_del_res(uid,pid,e,res )--取出资源
    local u = unionmng.get_union(uid)
    if not u  then
        WARN("not union")
        return false
    end

    if not e then
        for _, v in pairs(u.build ) do
            local c = resmng.get_conf("prop_world_unit",v.propid)
            if c.Mode == resmng.CLASS_UNION_BUILD_RESTORE then--仓库
                e = v
                break
            end
        end
    end

    if not e  then
        return false
    end

    if not u.restore then return false  end
    for k, v in pairs(u.restore.sum or {}) do
        if not pid  then--全取时需要创建行军队列
            if not res then 
                res = copyTab(v.res)
            end
            local p = getPlayer(v.pid)
            local troop = troop_mng.create_troop(TroopAction.GetRes, p, e)
            troop.curx, troop.cury = get_ety_pos(e)
            troop:set_extra("union_expect_res", res) 
            troop_mng.trigger_event(troop)
        elseif v.pid == pid then
            if not res then 
                res = copyTab(v.res)
                local p = getPlayer(v.pid)
                local troop = troop_mng.create_troop(TroopAction.GetRes, p, e)
                troop.curx, troop.cury = get_ety_pos(e)
                troop:set_extra("union_expect_res", res) 
                troop_mng.trigger_event(troop)
                gPendingSave.union_t[ u._id ].restore = u.restore
                return true
            else
                if not can_res(u,v.pid,res) then
                    return false
                end

                local f = true 
                for i = 1, #res do
                    v.res[i] = v.res[i] - res[i] 
                    if v.res[i]~= 0  then
                        f = false
                    end
                end
                if f==true then
                    u.restore.sum[k]= nil 
                end
                gPendingSave.union_t[u._id].restore = u.restore
                return true
            end
        end

    end
    gPendingSave.union_t[u._id].restore = u.restore
    return true
end

function market_del( e,pid,res )--下架特产
    if not pid then pid = 0  end
    if not res then res = {}  end
    local u = unionmng.get_union(e.uid)
    if not u.restore then return false  end
    for _, v in pairs(u.market or {}) do
        local p = getPlayer(v.pid)
        if pid == 0 then--拆除建筑需要创建行军队列返回
                res = v.res
                v.res = 0
                local t = troop_mng.create_troop(e.eid,p.eid,TroopAction.Back,e.x,e.y,p.x,p.y)
                t.owner_pid= p.pid
                t.speed = t:calc_troop_speed()
                troop_mng.mount_bonus(t,res)
                t:start_march()
        elseif v.pid == pid then
            if not can_market(u,v.pid,res) then
                return false
            end
            for i = 1, #res do
                v.res[i] = v.res[i] - res[i]
            end
        end

    end
	gPendingSave.union_t[u._id].market = u.market
    return true
end

function market_add(e, pid,res )--上架特产

    local u = unionmng.get_union(e.uid)
    if not u.market then u.market={ } end
    local f = 0
    for _, v in pairs(u.market  ) do
        if v.pid == pid then

        for k, vv in pairs(res) do
            v.res[k] = (v.res[k] or 0 ) + vv
        end
        f =1
		break
		end
    end

    if f ==0 then
        table.insert(u.market,{pid=pid,res=res})
    end
	gPendingSave.union_t[u._id].market = u.market
end

function restore_add_res(e, pid,res )--存储资源

    local u = unionmng.get_union(e.uid)
    if (not u.restore) or (not next(u.restore)) then u.restore={ sum={},day={}} end
    if not u.restore.sum then u.restore.sum={} end
    if not u.restore.day then u.restore.day={} end

    local f = 0
    for _, v in pairs( u.restore.sum or {}  ) do
        if v.pid == pid then
            for k, vv in pairs(res) do
                v.res[k] = (v.res[k] or 0 ) + vv
            end
            f =1
            break
        end
    end
    if f ==0 then
        table.insert(u.restore.sum,{pid=pid,res=res})
    end

    f=0
    for _, v in pairs(u.restore.day or {} ) do
        if v.pid == pid then
            if can_date(v.time) then
                v.num = 0
            end
            for k, num in pairs(res ) do
				v.num = v.num + calc_res(k,num)
			end
            v.time = gTime
            f=1
            break
        end
    end

    if f==0 then
        local num = 0
		for k, v in pairs(res ) do
			num = num + calc_res(k,v)
		end
        table.insert(u.restore.day,{pid=pid,num=num,time=gTime})
    end

	gPendingSave.union_t[u._id].restore = u.restore
end

function get_res_day(u, pid )--计算当天已存储量
    local sum = 0
    if u and u.restore then 
        for _, v in pairs(u.restore.day or {}) do
            if v.pid == pid then
                sum = v.num
                break
            end
        end
    end

    local p = getPlayer(pid)
    if p then
        for _, v in pairs(p.busy_troop_ids) do
            local t  = troop_mng.get_troop(v)
            if t.action == resmng.TroopAction.SaveRes + 100  then
                local res = t:get_extra("union_save_res") 
                for k, v in pairs(res or {}) do
                    sum = sum + calc_res(k,v)
                end
            end
        end
    end
    return sum
end

function get_res_count(u, pid )--计算总存储量
    local sum = 0
    if u and u.restore then 
        for _, v in pairs(u.restore.sum or {}) do
            if (pid and v.pid == pid ) or (not pid) then
                for k, num in pairs(v.res or {}) do
                    sum = sum + calc_res(k,num)
                end
                break
            end
        end
    end

    local p = getPlayer(pid)
    if p then
        for _, v in pairs(p.busy_troop_ids) do
            local t  = troop_mng.get_troop(v)
            if t.action == resmng.TroopAction.SaveRes + 100  then
                local res = t:get_extra("union_save_res") 
                for k, v in pairs(res or {}) do
                    sum = sum + calc_res(k,v)
                end
            end
        end
    end
    return sum
end

function can_res(u,pid,r)--能否取出资源
    if not u.restore then return false  end
    for _, v in pairs(u.restore.sum or {}) do
        if v.pid == pid then
            for i = 1, #r do
                if (not v.res[i]) or (r[i] > v.res[i]) then
                    return false
                end
            end
        end
    end
    return true
end

function can_market(u,pid,r)--能否取出
    for _, v in pairs(u.market or {}) do
        if v.pid == pid then
            for _, vv in pairs(r or {}) do
                for i = 1, #r do
                    if r.propid and (not vv.res[i]) and (r[i] > vv.res[i]) then
                        return false
                    end
                end
            end
        end
    end
    return true
end


function get_restore_limit(p,dp)--计算军团仓库上限
    local pack = {
        sum = {},day={}
    }
    --todo, what?

    local u = unionmng.get_union(p.uid)
    if not u then
        ack(p, "get_eye_info", resmng.E_NO_UNION) return
    end

    pack.day.limit = u:get_day_store(p,dp)
    pack.sum.limit = u:get_sum_store(p,dp)
    pack.day.num   = get_res_day(u,p.pid)
    pack.sum.num   = get_res_count(u,p.pid)

    return pack
end


function arms(obj)
    if not is_union_building(obj) then return false end

    local cc = resmng.get_conf("prop_world_unit",obj.propid) or {}
    if not cc then return false end

    local arms  
    if cc.Mode == resmng.CLASS_UNION_BUILD_MINE
        or cc.Mode == resmng.CLASS_UNION_BUILD_FARM
        or cc.Mode == resmng.CLASS_UNION_BUILD_LOGGINGCAMP
        or cc.Mode == resmng.CLASS_UNION_BUILD_QUARRY then
        for _, v in pairs(obj.my_troop_id or {} ) do
                if not arms then
                    arms = Copytab(v)
                else
                    troop_t.add_to( v, arms )
                end
        end
    else
       arms = troop_mng.get_troop(obj.my_troop_id)
    end
    return arms
end

function can_troop(action, p, eid, res)--行军队列发出前判断

    if player_t.debug_tag then
        return true
    end
    
    local dp = get_ety(eid)
    if not dp then 
        WARN("")
        return false 
    end
    if not is_union_building(dp) then 
        WARN("")
        return false 
    end

    local cc = resmng.get_conf("prop_world_unit",dp.propid) or {}
    if not cc then 
        WARN("")
        return false 
    end

    if action ~= TroopAction.UnionBuild and action ~= TroopAction.SiegeUnion then
        if dp.state ~= BUILD_STATE.WAIT then
            WARN("建筑没准备好")
            return false
        end
    end

    if action == TroopAction.HoldDefense then
        if dp.uid == p.uid then
            local t = troop_mng.get_troop(dp.my_troop_id)
            if t then
                for pid, _ in pairs(t.arms or {} ) do
                    if pid == p.pid then
                        WARN("")
                        return false
                    end
                end
            end

            if is_union_miracal(dp.propid) then
                local sum,max = p:get_hold_limit(dp)
                if sum <= max then
                    return true
                end
            end
        end
    elseif action == TroopAction.SiegeUnion then
        if p.uid ~= dp.uid then
            if is_union_miracal(dp.propid) then
                return true
            end
        end

    elseif action == TroopAction.Gather then
        if dp.uid == p.uid then
            local t = troop_mng.get_troop(dp.my_troop_id)
            if t then
                for pid, _ in pairs(t.arms or {} ) do
                    if pid == p.pid then
                        WARN("")
                        return false
                    end
                end
            end
        --todo
            if is_union_superres(dp.propid) then
                return true
            end
        end

    elseif action == TroopAction.UnionBuild or action == TroopAction.UnionFixBuild or action == UnionUpgradeBuild then

        local sum,max = p:get_hold_limit(dp)
        if sum <= max then
            LOG("到达驻守上限:"..sum..":"..max)
            return true
        end

    elseif action == resmng.TroopAction.SaveRes then
        if dp.uid == p.uid then
            if is_union_restore(dp.propid) then
                for mode, num in pairs(res or {} ) do
                    if num > p:get_res_num_normal(mode) then
                        return false
                    end
                end

                --仓库上限
                local d = get_restore_limit(p,dp)
                local sum = 0
				for k, num in pairs( res ) do
					sum = sum + calc_res(k,num)
				end
                if sum + d.sum.num > d.sum.limit then
                    WARN("到达上限:"..(sum+d.sum.num)..":"..d.sum.limit)
                    return false
                end

                if sum + d.day.num > d.day.limit then
                    WARN("到达上限:"..(sum)..":"..d.day.limit)
                    return false
                end
                return true
            end
        end
    elseif action == TroopAction.GetRes then
        local u = unionmng.get_union(dp.uid)
        if dp.uid == p.uid then
            if is_union_restore(dp.propid) then
                if can_res(u,p.pid,res) then
                    return true
                end
            end
        end
    end
    return false
end

function can_ef(build,ply) --奇迹内
    local c = resmng.get_conf("prop_world_unit", ply.propid) or {}
    local cc = resmng.get_conf("prop_world_unit", build.propid) or {}

    local x,y = ply.x, ply.y
    if x>=build.x-cc.Range and x<=build.x+cc.Size+cc.Range and y>=build.y-cc.Range and y<=build.y+cc.Size+cc.Range then
        return true
    end

    x,y= ply.x+c.Size, ply.y
    if x>=build.x-cc.Range and x<=build.x+cc.Size+cc.Range and y>=build.y-cc.Range and y<=build.y+cc.Size+cc.Range then
        return true
    end

    x,y = ply.x,ply.y + c.Size
    if x>=build.x-cc.Range and x<=build.x+cc.Size+cc.Range and y>=build.y-cc.Range and y<=build.y+cc.Size+cc.Range then
        return true
    end

    x,y = ply.x + c.Size, ply.y + c.Size
    if x>=build.x-cc.Range and x<=build.x+cc.Size+cc.Range and y>=build.y-cc.Range and y<=build.y+cc.Size+cc.Range then
        return true
    end

    return false
end

function acc(obj)--结算
    if is_union_building(obj) then
        if obj.my_troop_id and type(obj.my_troop_id)=="number" then -- 驻守
            local tr = troop_mng.get_troop(obj.my_troop_id)
            local ssum =0  
            if  tr then
                for pid, arm in pairs(tr.arms) do
                    local sum = 0
                    for id, num in pairs(arm.live_soldier or {}) do
                        sum = sum + num
                    end
                    if sum == 0  then
                        local one  = tr:split_pid(pid)
                        if one then
                            one:back()
                        end
                    end
                    ssum = ssum + sum
                end
            end
            if ssum == 0  then
                obj.my_troop_id = nil 
                obj.holding = 0
            else
                obj.holding = 1
            end
        elseif obj.my_troop_id and type(obj.my_troop_id)=="table" then -- 采集
            gather(obj)
        else
            local tr = troop_mng.get_troop(obj.my_troop_id)
            if not tr then
                obj.my_troop_id = nil 
            end
            obj.holding = 0
        end
        building(obj) --部队修理
    end
end

function save(obj)
    if is_union_building(obj) then
        acc(obj)

        if  obj.hp <= 0 then
            remove(obj)
            return
        end

        if obj.val and obj.val == 0 then
            remove(obj)
            return 
        end


        gEtys[obj.eid] = obj
        etypipe.add(obj)
        gPendingSave.union_build[obj._id] = obj
        local u = unionmng.get_union(obj.uid)
        if u then
            u.build[obj.idx] = obj
            u:notifyall("build", resmng.OPERATOR.UPDATE, obj)
        end
    end
end

function del(e)
    if is_union_building(e) then
        e.state = BUILD_STATE.DESTROY
        local u = unionmng.get_union(e.uid)
        if u then
            u.build[e.idx] = e
            u:notifyall("build", resmng.OPERATOR.DELETE, e)
        end
        gPendingSave.union_build[e._id] = e
        c_rem_ety(e.eid)
        gEtys[e.eid] = nil
    end
end

function building(obj) --部队修理

    --先结算
    if obj.tmStart_b ~= 0 then
        obj.hp = obj.hp + obj.build_speed *(gTime - obj.tmStart_b)
        obj.tmStart_b = gTime
    end

    if obj.fire_tmStart ~= 0 then
        obj.hp = obj.hp + obj.fire_speed *(gTime - obj.fire_tmStart)
        if obj.hp < min_hp  then
            obj.hp = 0  
            timer.del(obj.tmSn)
            timer.del(obj.fire_tmSn)
            return
        end
        if obj.fire_tmSn == 0 then
            obj.fire_tmStart = 0
            obj.fire_speed = 0
            obj.fire_tmOver = 0
        else
            obj.fire_tmStart = gTime
        end
    end


    local obj_id = obj.propid
    if obj.state == BUILD_STATE.UPGRADE then 
        local c = resmng.get_conf("prop_world_unit",obj.propid)
        if not c  then 
            exception_troop_back(troop)
            return 
        end

        local id  = union_buildlv.get_buildlv(obj.uid, c.BuildMode).id
        if not id  then 
            exception_troop_back(troop)
            return 
        end

        local cc = resmng.get_conf("prop_union_buildlv",id)
        if not cc  then 
            exception_troop_back(troop)
            return 
        end

        if c.Lv < cc.Lv then
            obj_id = obj.propid - c.Lv + cc.Lv  
        end
    end

    local maxhp = resmng.get_conf("prop_world_unit", obj_id).Hp
    if player_t.debug_tag then obj.hp = maxhp  end
    if obj.hp >=  maxhp then 
        obj.propid = obj_id
        obj.hp = maxhp 
        obj.tmStart_b = 0
        obj.tmOver_b = 0
        obj.tmSn = 0
        obj.build_speed = 0
        obj.state = BUILD_STATE.WAIT
        union_build_t.buf_open(obj)
        troop_mng.work(obj)
        return
    end

    local tr = troop_mng.get_troop(obj.my_troop_id)
    if not tr then
        timer.del(obj.tmSn)
        obj.tmStart_b = 0
        obj.tmOver_b = 0
        obj.build_speed = 0
        return
    else
        tr.action =TroopAction.UnionBuild+200  

        local pow = 0
        for _, v in pairs(tr.arms) do
            local sum = 0
            for id, num in pairs(v.live_soldier or {}) do
                sum = sum + num
                if num ~=0 then
                    local conf = resmng.get_conf("prop_arm", id)
                    if conf then
                        pow = pow + conf.Pow * num
                    end
                end
            end

            if sum == 0  then
                local one = tr:split_pid(v.pid)
                if one then
                    one:back()
                end
            else
                local ply = getPlayer(v.pid) 
                ply:date_add("build")
                if ply and ply:is_online() then
                    Rpc:stateTroop(ply, tr)
                end
            end
        end

        local c = resmng.get_conf("prop_world_unit", obj.propid)
        if not  c then
            return
        end
        local speed = pow *(c.Speed or 0) /(1000*10000 )
        tr:set_extra("speed", speed )
    end

    local remain = maxhp - obj.hp
    local build_speed = tr:get_extra("speed")  
    if build_speed < 0 then build_speed = 0 end

    obj.build_speed = build_speed

    if build_speed > 0 then
        local tm_need = math.ceil(remain/build_speed)
        obj.tmSn = timer.new("union_build_complete", tm_need, obj.eid)
        obj.tmOver_b = gTime + tm_need
    else
        timer.del(obj.tmSn)
        obj.tmStart_b = 0
        obj.tmOver_b = 0
        obj.tmSn = 0
    end

    tr.tmStart = gTime
    tr.tmOver = 0
    tr.tmSn = 0
    tr.tmOver = obj.tmOver_b
    save_ety(tr)
end

function gather(obj ) --采集
    
    local remain = obj.val 
    if obj.tmStart_g ~= 0  then
        remain = remain - obj.speed * (gTime - obj.tmStart_g)
    end

    if remain < 0 then remain = 0 end

    local speed = 0
    local ids = obj.my_troop_id
    if ids then
        if type(ids) == "number" then
            ids = {ids}
            obj.my_troop_id = ids
        end

        for _, tid in pairs(ids) do
            local tr = troop_mng.get_troop(tid)
            if tr then speed = speed + (tr:get_extra("speed") or 0)  end
        end
    end
    if speed < 0 then speed = 0 end

    obj.val = remain
    obj.speed = speed
    obj.tmStart_g = gTime

    if remain > 0 and speed > 0 then
        local tm_need = math.ceil(remain / speed)
        obj.tmSn = timer.new("union_gather_empty", tm_need, obj.eid)
        obj.tmOver_g = gTime + tm_need
    else
        timer.del(obj.tmSn)
        obj.tmSn = nil
        obj.tmOver_g = 0
    end

    local tmOver = obj.tmOver_g
    for _, tid in pairs(ids or {}) do
        local tr = troop_mng.get_troop(tid)
        if tr then
            if tr.tmOver > tmOver then
                tr.tmOver = tmOver
                tr.tmSn = timer.new("troop", tmOver - gTime, tr.owner_pid, tr._id)
                local pl = getPlayer(tr.owner_pid)
                if pl and pl:is_online() then
                    Rpc:stateTroop(pl, tr)
                end
            end
        end
    end

end

function fire(obj,s)
    local tm = s or 10 
    obj.fire_speed = -0.5

    if obj.hp + obj.fire_speed*tm  < 0  then
        tm = math.ceil(-obj.hp/obj.fire_speed)
    end

    obj.fire_tmStart = gTime
    if obj.fire_tmSn~= 0  then
        obj.fire_tmOver = obj.fire_tmOver + tm
    else
        obj.fire_tmOver = obj.fire_tmStart + tm
    end
    local need = obj.fire_tmOver - obj.fire_tmStart  
    obj.fire_tmSn = timer.new("union_build_fire", need, obj.eid)
    save_ety(obj)

end

function buf_open(e)--奇迹生成
    local c = resmng.get_conf("prop_world_unit", e.propid)
    if is_union_miracal(e.propid) then
        local es = get_around_eids( e.eid, c.Range ) 
        if not es then return end
        for _, eid in pairs( es ) do
            if is_ply(eid) then
                local ply = get_ety(eid) 
                if  union_build_t.can_ef(e,ply) then
                    local old = {sn=math.huge }
                    if ply.ef_eid then
                        local tmp = get_ety(ply.ef_eid)
                        if tmp  then
                            old = tmp
                            if e.sn <= old.sn  or ply.ef_eid == e.eid then
                                ply.ef_eid = e.eid
                            end
                        else
                            ply.ef_eid = e.eid
                        end
                    else
                        ply.ef_eid = e.eid
                    end

                end
            end
        end
    end
end

function buf_close(e)--奇迹移除
    local c = resmng.get_conf("prop_world_unit", e.propid)
    if is_union_miracal(e.propid) then
        local es = get_around_eids( e.eid, c.Range ) 
        if not es then return end
        for _, eid in pairs( es ) do
            if is_ply(eid) then
                local ply = get_ety(eid) 
                if e.eid == ply.ef_eid then
                    ply.ef_eid = 0 
                    local builds = get_around_eids( ply.eid, 25 ) 
                    if builds then 
                        local sn  = math.huge
                        for _, eid in pairs( builds ) do
                            if is_union_building(eid) then
                                local b = get_ety(eid) 
                                if is_union_miracal(b.propid) then
                                    if b.sn < sn then
                                        ply.ef_eid = b.eid
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function ply_move(ply)--迁城变奇迹影响

    ply.ef_eid = 0 
    local builds = get_around_eids( ply.eid, 25 ) 
    if not builds then return end

    local sn  = math.huge
    for _, eid in pairs( builds ) do
        if is_union_building(eid) then
            local e = get_ety(eid) 
            if is_union_miracal(e.propid) then
                if  union_build_t.can_ef(e,ply) then
                    if e.sn < sn then
                        ply.ef_eid = e.eid
                        sn = e.sn
                    end
                end
            end
        end
    end

end
