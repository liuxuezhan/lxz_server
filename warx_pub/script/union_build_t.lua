
--------------- 军团建筑模块 -----------------------------------------------------------

module(..., package.seeall)
 _sn = 0--建造时间顺序

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

            print("union_build,", data.eid)
            mark_eid(data.eid)
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
    if not cc and cc.Class ~= BUILD_CLASS.UNION then return end
    --TODO: 地图空位检测
    if c_map_test_pos(x, y, cc.Size) ~= 0 then return end

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
            hp = 0,
            x = x,
            y = y,
            size = cc.Size,
            propid = propid,
            range = 0,
            state = BUILD_STATE.CREATE,
            sn = _sn,
            val = cc.Count or 0,
            speed = 0,
            tmStart = 0,
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
        e.hp = 0
        e.x = x
        e.y = y
        e.speed = 0
        e.tmStart = 0
        e.name = name
        e.fire_tmStart = 0
        e.fire_tmOver = 0
        e.fire_speed = 0
        e.fire_tmSn = 0
        e.tmSn = 0
        e.val = cc.Count or 0
        e.state = BUILD_STATE.CREATE
        save_ety(e)
    end
    u:add_log(resmng.UNION_EVENT.BUILD_SET, resmng.UNION_MODE.ADD,{propid=e.propid,name=e.name})
end

function remove(e)
    if not e then return end
    local u = unionmng.get_union(e.uid)
    if not u then return end

    local bcc = resmng.get_conf("prop_world_unit",e.propid)
    if not bcc then return false end

    local ret = union_build_t.remove_build(e)

--拆除奇迹相关建筑
    if bcc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or bcc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        for k, v in pairs(u.build) do
            local cc = resmng.get_conf("prop_world_unit",v.propid)
            if cc.Mode ~= resmng.CLASS_UNION_BUILD_CASTLE and cc.Mode ~= resmng.CLASS_UNION_BUILD_MINI_CASTLE then
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

    if bcc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or bcc.Mode ==resmng.CLASS_UNION_BUILD_MINI_CASTLE then   --驻守返回
        local tr = troop_mng.get_troop(e.my_troop_id)
        if tr then
            for _, v in pairs(tr.arms) do
                local one = tr:split_pid(v.pid)
                local ply = getPlayer(v.pid)
                ply:troop_recall(one._id)
            end
        end
        del(e)

    elseif bcc.Mode == resmng.CLASS_UNION_BUILD_FARM
        or bcc.Mode ==resmng.CLASS_UNION_BUILD_LOGGINGCAMP
        or bcc.Mode ==resmng.CLASS_UNION_BUILD_MINE
        or bcc.Mode ==resmng.CLASS_UNION_BUILD_QUARRY  then     --采集返回

        if type(e.my_troop_id)=="table" then
            for k, v in pairs(e.my_troop_id or {} ) do
                local one = troop_mng.get_troop(v)
                local ply = getPlayer(one.owner_pid)
                ply:troop_recall(one._id)
            end
        end
        del(e)
    elseif bcc.Mode == resmng.CLASS_UNION_BUILD_RESTORE then--仓库
        for _, v in pairs(u.build ) do
            local c = resmng.get_conf("prop_world_unit",v.propid)
            if c.Mode == resmng.CLASS_UNION_BUILD_RESTORE and v.state~= BUILD_STATE.DESTORY then--仓库
                f = 1
                break
            end
        end
        if f== 0 then
            restore_del_res(e.uid)--取出资源
        end
        del(e)
    elseif bcc.Mode == resmng.CLASS_UNION_BUILD_MARKET then        --市场
        local f =0
        for _, v in pairs(u.build ) do
            local c = resmng.get_conf("prop_world_unit",v.propid)
            if c.Mode == resmng.CLASS_UNION_BUILD_MARKET and v.state~= BUILD_STATE.DESTORY then--仓库
                f = 1
                break
            end
        end
        if f== 0 then
            market_del(e)--取出
        end
        del(e)
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
    for _, v in pairs(u.restore.sum or {}) do
        if not pid  then--全取时需要创建行军队列
            if not res then res = v.res  end
            v.res = 0
            local p = getPlayer(v.pid)
            local troop = troop_mng.create_troop(TroopAction.GetRes, p, e)
            troop:set_extra("union_expect_res", res) 
            troop_mng.trigger_event(troop)
        elseif v.pid == pid then
            if not res then 
                res = v.res  
                local p = getPlayer(v.pid)
                local troop = troop_mng.create_troop(TroopAction.GetRes, p, e)
                troop:set_extra("union_expect_res", res) 
                troop_mng.trigger_event(troop)
                gPendingSave.union[u._id].restore = u.restore
                return true
            else
                if not can_res(u,v.pid,res) then
                    return false
                end
                for i = 1, #res do
                    v.res[i] = v.res[i] - res[i]
                end
                gPendingSave.union[u._id].restore = u.restore
                return true
            end
        end

    end
    gPendingSave.union[u._id].restore = u.restore
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
	gPendingSave.union[u._id].market = u.market
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
	gPendingSave.union[u._id].market = u.market
end

function restore_add_res(e, pid,res )--存储资源

    local u = unionmng.get_union(e.uid)
    if not u.restore then u.restore={ sum={},day={}} end
    local f = 0
    for _, v in pairs(u.restore.sum  ) do
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
    for _, v in pairs(u.restore.day ) do
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

	gPendingSave.union[u._id].restore = u.restore
end

function get_res_day(u, pid )--计算当天已存储量
    if not u.restore then return 0  end
    for _, v in pairs(u.restore.day or {}) do
        if v.pid == pid then
            return v.num
        end
    end
    return 0
end

function get_res_count(u, pid )--计算总存储量
    if not u then return 0  end
    if not u.restore then return 0  end
    for _, v in pairs(u.restore.sum or {}) do
        if (pid and v.pid == pid ) or (not pid) then
			local sum = 0
			for k, num in pairs(v.res or {}) do
				sum = sum + calc_res(k,num)
			end
            return sum
        end
    end
    return 0
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


function get_restore_limit(p)--计算军团仓库上限
    local pack = {
        sum = {},day={}
    }
    --todo, what?

    local u = unionmng.get_union(p.uid)
    if not u then
        ack(p, "get_eye_info", resmng.E_NO_UNION) return
    end

    pack.day.limit = u:get_day_store(p)
    pack.sum.limit = u:get_sum_store(p)
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
    local dp = get_ety(eid)
    if not dp then 
        WARN()
        return false 
    end
    if not is_union_building(dp) then 
        WARN()
        return false 
    end

    local cc = resmng.get_conf("prop_world_unit",dp.propid) or {}
    if not cc then 
        WARN()
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
                        WARN()
                        return false
                    end
                end
            end

            if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
                local sum,max = p:get_hold_limit(dp)
                if sum <= max then
                    return true
                end
            end
        end
    elseif action == TroopAction.SiegeUnion then
        if p.uid ~= dp.uid then
            if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
                return true
            end
        end

    elseif action == TroopAction.Gather then
        if dp.uid == p.uid then
            local t = troop_mng.get_troop(dp.my_troop_id)
            if t then
                for pid, _ in pairs(t.arms or {} ) do
                    if pid == p.pid then
                        WARN()
                        return false
                    end
                end
            end
        --todo
            if cc.Mode == resmng.CLASS_UNION_BUILD_MINE
			or cc.Mode == resmng.CLASS_UNION_BUILD_FARM
			or cc.Mode == resmng.CLASS_UNION_BUILD_LOGGINGCAMP
			or cc.Mode == resmng.CLASS_UNION_BUILD_QUARRY then
                return true
            end
        end

    elseif action == TroopAction.UnionBuild or action == TroopAction.UnionFixBuild or action == UnionUpgradeBuild then

        local sum,max = p:get_hold_limit(dp)
        if sum <= max then
            return true
        end
        WARN("到达驻守上限:"..sum..":"..max)

    elseif action == resmng.TroopAction.SaveRes then
        if dp.uid == p.uid then
            if cc.Mode == resmng.CLASS_UNION_BUILD_RESTORE then
                for mode, num in pairs(res or {} ) do
                    if num > p:get_res_num_normal(mode) then
                        return false
                    end
                end

                --仓库上限
                local d = get_restore_limit(p)
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
            if cc.Mode == resmng.CLASS_UNION_BUILD_RESTORE then
                if can_res(u,p.pid,res) then
                    return true
                end
            end
        end
    end
    return false
end

function can_ef(build,ply)
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

function save(e)
    if is_union_building(e) then
        gEtys[e.eid] = e
        etypipe.add(e)
        gPendingSave.union_build[e._id] = e
        local u = unionmng.get_union(e.uid)
        if u then
            u.build[e.idx] = e
            u:notifyall("build", resmng.OPERATOR.UPDATE, e)
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


function troop_update(self, what)
    if what == "gather" then
        local remain = self.val - self.speed * (gTime - self.tmStart)
        if remain < 0 then remain = 0 end

        local speed = 0
        local ids = self.my_troop_id
        if ids then
            if type(ids) == "number" then
                ids = {ids}
                self.my_troop_id = ids
            end

            for _, tid in pairs(ids) do
                local tr = troop_mng.get_troop(tid)
                if tr then speed = speed + (tr:get_extra("speed") or 0)  end
            end
        end
        if speed < 0 then speed = 0 end

        self.val = remain
        self.speed = speed
        self.tmStart = gTime

        if remain > 0 and speed > 0 then
            local tm_need = math.ceil(remain / speed)
            self.tmSn = timer.new("union_gather_empty", tm_need, self.eid)
            self.tmOver = gTime + tm_need
        else
            timer.del(self.tmSn)
            self.tmSn = nil
            self.tmOver = 0
        end

        local tmOver = self.tmOver
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
        save_ety(self)
        return
    end

    if what == "build" then
        local maxhp = resmng.get_conf("prop_world_unit", self.propid).Hp
        
        if self.tmStart ~= 0 then
            self.hp = self.hp + self.speed *(gTime - self.tmStart)
        end
        self.tmStart = gTime

        if self.fire_tmStart ~= 0 then
            self.hp = self.hp + self.fire_speed *(gTime - self.fire_tmStart)
            if self.fire_tmSn == 0 then
                self.fire_tmStart = 0
                self.fire_speed = 0
                self.fire_tmOver = 0
            else
                self.fire_tmStart = gTime
            end
        end

        if self.hp < 0  then
            timer.del(self.tmSn)
            timer.del(self.fire_tmSn)
            rem_ety(self.eid)
            return
        end

        if self.hp >=  maxhp then
            self.hp = maxhp 
            self.tmStart = 0
            self.tmOver = 0
            self.tmSn = 0
            self.speed = 0
            self.state = BUILD_STATE.WAIT
            save_ety(self)
            troop_mng.work(self)
            return
        end

        local tr = troop_mng.get_troop(self.my_troop_id)
        if not tr then
            timer.del(self.tmSn)
            self.tmStart = 0
            self.tmOver = 0
            self.speed = 0
            save_ety(self)
            return
        end

        local remain = maxhp - self.hp
        speed = tr:get_extra("speed")  
        if speed < 0 then speed = 0 end

        self.speed = speed

        if speed > 0 then
            local tm_need = math.ceil(remain/speed)
            self.tmSn = timer.new("union_build_complete", tm_need, self.eid)
            self.tmOver = gTime + tm_need
        else
            timer.del(self.tmSn)
            self.tmStart = 0
            self.tmOver = 0
            self.tmSn = 0
        end

        tr.tmStart = gTime
        tr.tmOver = 0
        tr.tmSn = 0
        tr.tmOver = self.tmOver
        save_ety(tr)
        save_ety(self)
        return
    end
end

function fire(self,s)
    
    local tm = s or 60
    self.fire_speed = -1

    self.fire_tmStart = gTime
    if self.fire_tmSn~= 0  then
        self.fire_tmOver = self.fire_tmOver + tm
    else
        self.fire_tmOver = self.fire_tmStart + tm
    end
    local need = self.fire_tmOver - self.fire_tmStart  
    self.fire_tmSn = timer.new("union_build_fire", need, self.eid)
    save_ety(self)

end


