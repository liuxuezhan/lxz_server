-- -----------------------------------------------------------------------------
module(..., package.seeall)
local build_sn = 0

function set_sn(sn)
    if build_sn < (sn or 0 ) then
        build_sn = sn
    end
end

function restore_del_res(e,pid,res )--取出资源
    if not pid then pid = 0  end
    if not res then res = {}  end
    local u = unionmng.get_union(e.uid)
    if not u.restore then return false  end
    for _, v in pairs(u.restore.sum or {}) do
        local p = getPlayer(v.pid)
        if pid == 0 then--全取时需要创建行军队列
                res = v.res
                v.res = 0
                local t = troop_mng.create_troop(e.eid,p.eid,TroopAction.Back,e.x,e.y,p.x,p.y)
                t.owner_pid= p.pid
                t.speed = t:calc_troop_speed()
                troop_mng.mount_bonus(t,res)
                t:start_march()
        elseif v.pid == pid then
            if not can_res(u,v.pid,res) then
                return false
            end
            for i = 1, #res do
                v.res[i] = v.res[i] - res[i]
            end
        end

    end
    dbmng:getOne().union:update({_id=u._id}, { ["$set"]={restore=u.restore}})
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

function remove_build(u, idx)
    if not u.build[idx] then return end
    local e = get_ety(u.build[idx].eid)
    if not e then return end
    local bcc = resmng.get_conf("prop_world_unit",e.propid) or {}
    if not bcc then return false end

    e.state = BUILD_STATE.DESTORY
    if bcc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or bcc.Mode ==resmng.CLASS_UNION_BUILD_MINI_CASTLE then   --驻守返回
        local t = troop_mng.get_troop(e.my_troop_id)
        if t then
        local ts = troop_mng.disperse_troop(t)
        for _, v in pairs(ts) do
            t = troop_mng.get_troop(v)
            t.speed = t:calc_troop_speed()
            t:start_march()
        end
		end
    elseif bcc.Mode == resmng.CLASS_UNION_BUILD_TUTTER1 or bcc.Mode ==resmng.CLASS_UNION_BUILD_TUTTER2  then   --驻守返回
        local t = troop_mng.get_troop(e.my_troop_id)

        if t then
        local ts = troop_mng.disperse_troop(t)
        for _, v in pairs(ts) do
            t = troop_mng.get_troop(v)
            t.speed = t:calc_troop_speed()
            t:start_march()
        end
		end
    elseif bcc.Mode == resmng.CLASS_UNION_BUILD_FRAM
		or bcc.Mode ==resmng.CLASS_UNION_BUILD_LOGGINGCAMP
		or bcc.Mode ==resmng.CLASS_UNION_BUILD_MINE
		or bcc.Mode ==resmng.CLASS_UNION_BUILD_QUARRY  then     --采集返回

        for k, v in pairs(e.my_troop_id) do
            local t = troop_mng.get_troop(v)
        end
    elseif bcc.Mode == resmng.CLASS_UNION_BUILD_RESTORE then--仓库
        local f =0
        for _, v in pairs(u.build ) do
            local c = resmng.get_conf("prop_world_unit",v.propid)
            if c.Mode == resmng.CLASS_UNION_BUILD_RESTORE and v.state~= BUILD_STATE.DESTORY then--仓库
                f = 1
                break
            end
        end
        if f== 0 then
            restore_del_res(e)--取出资源
        end
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
    end
    c_rem_ety(e.eid)
    gEtys[e.eid] = nil
    u:notifyall("build", resmng.OPERATOR.DELETE, {idx=idx})
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

function can_troop(action, p, eid, res)--行军队列发出前判断
    local dp = get_ety(eid)
    if not dp then return false end
    if not is_union_building(dp) then return false end

    local cc = resmng.get_conf("prop_world_unit",dp.propid) or {}
    if not cc then return false end

    if action == TroopAction.HoldDefense then
        if dp.uid == p.uid then
            local t = troop_mng.get_troop(dp.my_troop_id)
            if t then
                for pid, _ in pairs(t.arms or {} ) do
                    if pid == p.pid then
                        return false
                    end
                end
            end

            if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
                return true
            end
        end
    elseif action == TroopAction.Seige then
        --todo
        if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
            return true
        end

    elseif action == TroopAction.Gather then
        if dp.uid == p.uid then
            local t = troop_mng.get_troop(dp.my_troop_id)
            if t then
                for pid, _ in pairs(t.arms or {} ) do
                    if pid == p.pid then
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

    elseif action == TroopAction.UnionBuild then
        return true
    elseif action == TroopAction.UnionFixBuild then
        return true
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
                    return false
                end

                if sum + d.day.num > d.day.limit then
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

function create(uid,idx, propid, x, y)

    assert(idx and propid and  uid and  x and y)
    local u = unionmng.get_union(uid)

    local cc = resmng.get_conf("prop_world_unit",propid) or {}
    if not cc and cc.Class ~= BUILD_CLASS.UNION then return end
    --TODO: 地图空位检测
    if c_map_test_pos(x, y, cc.Size) ~= 0 then
        return
    end

    local data
    build_sn = build_sn + 1
    --if not u:can_build(propid,x,y) then return end
    if idx == 0 then
        idx = #u.build+1
        local _id = string.format("%s_%s", idx, uid)
        data = {
            _id = _id,
            eid = get_eid_uion_building(),
            idx = idx,
            uid = uid,
            hp = 0,
            x = x,
            y = y,
            size = cc.Size,
            propid = propid,
            range = 0,
            state = BUILD_STATE.CREATE,
            sn = build_sn,
            val = cc.Count or 0,
            speed = 0,
            tmStart = 0,
            name = "",
        }
        u.build[idx] = data
    else
        u.build[idx].eid = get_eid_uion_building()
        u.build[idx].sn = build_sn
        u.build[idx].hp = 0
        u.build[idx].speed = 0
        u.build[idx].tmStart = 0
        u.build[idx].val = cc.Count or 0
        u.build[idx].state = BUILD_STATE.CREATE
    end
     gPendingSave.union_build[u.build[idx]._id] = u.build[idx]
     all(u.build[idx])

    etypipe.add(u.build[idx])
	gEtys[u.build[idx].eid] = u.build[idx]
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

function all(v)--广播
    local u = unionmng.get_union(v.uid)
    u:notifyall("build", resmng.OPERATOR.UPDATE, v)
end

function on_destory(self)
    local db = dbmng:getOne()
    all(self)
    db.union_build:delete({_id=self._id})
end

function get_range(self)
    assert(self)
    return self:get_ef().Range or 0
end

function mark(e)
    if is_union_building(e) then
        gPendingSave.union_build[e._id] = e
        all(e)
    end
end

function troop_update(self, what)
    gPendingSave.union_build[self._id] = self
    all(self)
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
                if tr then speed = speed + tr:get_extra("speed") end
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
                    if pl and pl.is_online() then
                        Rpc:stateTroop(pl, tr)
                    end
                end
            end
        end
        etypipe.add(self)
        return
    end

    if what == "build" then
        local maxhp = resmng.get_conf("prop_world_unit", self.propid).Hp
        local hp = self.hp + self.speed * (gTime - self.tmStart)

        local remain = maxhp - hp
        local ids = self.my_troop_id
        local speed = 0
        if ids then
            if type(ids) == "number" then
                ids = {ids}
                self.my_troop_id = ids
            end
            for _, tid in pairs(ids) do
                local tr = troop_mng.get_troop(tid)
                if tr then speed = speed + tr:get_extra("speed") end
            end
        end
        if speed < 0 then speed = 0 end

        self.hp = hp
        self.speed = speed
        self.tmStart = gTime

        if speed > 0 then
            local tm_need = math.ceil(remain/speed)
            self.tmSn = timer.new("union_build_complete", tm_need, self.eid)
            self.tmOver = gTime + tm_need
        else
            timer.del(self.tmSn)
            self.tmOver = 0
        end

        local tmOver = self.tmOver
        for _, tid in pairs(ids or {}) do
            local tr = troop_mng.get_troop(tid)
            if tr then
                tr.tmOver = tmOver
                local pl = getPlayer(tr.owner_pid)
                if pl and pl:is_online() then
                    Rpc:stateTroop(pl, tr)
                end
            end
        end
        return
    end
end


