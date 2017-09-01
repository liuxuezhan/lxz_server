
--------------- 军团建筑模块 -----------------------------------------------------------

module(..., package.seeall)
_sn = 0--建造时间顺序
local min_hp = 1
function load()
    local db = dbmng:getOne()
    local info = db.union_build:find({})
    while info:hasNext() do
        local data = info:next()
        if _sn < (data.sn or 0 ) then _sn = data.sn end
        local u = unionmng.get_union(data.uid)
        if u  then
            u.build[data.idx] = data
            if data.state ~= BUILD_STATE.DESTROY then
                gEtys[ data.eid ] = data
                data.culture = data.culture or 1
                etypipe.add(data)
            end
          end
    end
  end

function is_hold(e)
    local u = unionmng.get_union(e.uid)
    if is_union_restore(e.propid) then --仓库
        if not u:is_restore_empty() then return 1 end
        
    elseif is_union_miracal(e.propid)  then -- 驻守
        local tr = troop_mng.get_troop(e.my_troop_id)
        local ssum =0
        if  tr then
            for pid, arm in pairs(tr.arms) do
                local sum = 0
                for id, num in pairs(arm.live_soldier or {}) do
                    sum = sum + num
                end
                if sum == 0  then
                    local one  = tr:split_pid(pid)
                    if one then one:back() end
                end
                ssum = ssum + sum
            end
        end
        if ssum == 0  then
            e.my_troop_id = nil
        else 
            return 1 
        end
    elseif is_union_superres(e.propid)  then -- 采集
        if e.tmStart_g~=0  then return 1 end

    else
        local tr = troop_mng.get_troop(e.my_troop_id)
        if tr then return 1 end
        e.my_troop_id = nil 

    end
    return 0
end

function get_build_id( uid, propid )
    local conf_build = resmng.get_conf( "prop_world_unit", propid )
    if (not conf_build) or conf_build.Class ~= BUILD_CLASS.UNION then return end

    local build_lv = union_buildlv.get_buildlv( uid, conf_build.BuildMode )
    if not build_lv then return end

    local conf_buildlv = resmng.get_conf( "prop_union_buildlv", build_lv.id )
    if not conf_buildlv then return end

    return propid - conf_build.Lv + conf_buildlv.Lv
end

function create(uid,idx, propid, x, y,name)
    assert(idx and propid and  uid and  x and y)

    local u = unionmng.get_union(uid)
    if not u then return end

    local e
    if idx == 0 then
        propid = get_build_id( uid, propid )
        if not propid then return end

        local cc = resmng.get_conf("prop_world_unit",propid)
        if (not cc) or cc.Class ~= BUILD_CLASS.UNION then return end

        if c_map_test_pos_for_ply(x, y, cc.Size) ~= 0 then INFO("[UNION]军团建筑不在空地") return end
          if not u:can_build(propid,x,y) then return end

        idx = #u.build+1
        local _id = string.format("%s_%s", idx, uid)
        _sn = _sn + 1
        e = {
            _id = _id,
            eid = get_eid_uion_building(),
            sn = _sn,
            idx = idx,
            uid = uid,
            alias = u.alias,
            x = x,
            y = y,
            size = cc.Size,
            propid = propid,
            range = 0,
            name = name,
            holding = 0,

            state = BUILD_STATE.CREATE,
            hp = min_hp,
            val = cc.Count or 0,

            tmStart_g = 0,
            tmOver_g = 0,
            tmSn_g = 0,
            speed_g = 0,
            
            tmStart_b = 0,
            tmOver_b = 0,
            tmSn_b = 0,
            speed_b = 0,

            speed_f = 0,
            tmStart_f = 0,
            tmOver_f = 0,
            tmSn_f = 0,

        }
        if u.god then
            local c = resmng.get_conf("prop_union_god",u.god.propid)
            if c then e.culture =  c.Mode end
        end

        save(e)
    else
        e = u.build[idx]
        if not e then return end

        local cc = resmng.get_conf("prop_world_unit",e.propid)
        if (not cc) or cc.Class ~= BUILD_CLASS.UNION then return end
        if c_map_test_pos_for_ply(x, y, cc.Size) ~= 0 then INFO("[UNION]军团建筑不在空地") return end
        if not u:can_build(e.propid,x,y) then return end

        e.eid = get_eid_uion_building()

        _sn = _sn + 1
        e.sn = _sn

        if cc.Hp == e.hp then e.state = BUILD_STATE.WAIT
        else e.state = BUILD_STATE.CREATE end

        if e.hp == 0  or (cc.BuildMode == UNION_CONSTRUCT_TYPE.SUPERRES) then e.hp = min_hp end

        e.x = x
        e.y = y
        e.name = name
        e.holding = 0
        e.my_troop_id = nil
        e.val = cc.Count or 0

        e.speed_b = 0
        e.tmStart_b = 0
        e.tmOver_b = 0
        e.tmSn_b = 0

        e.speed_g = 0
        e.tmStart_g = 0
        e.tmOver_g = 0
        e.tmSn_g = 0

        e.speed_f = 0
        e.tmStart_f = 0
        e.tmOver_f = 0
        e.tmSn_f = 0

        save(e)
        if cc.Hp == e.hp then union_build_t.buf_open(e) end
    end
    u:add_log(resmng.UNION_EVENT.BUILD_SET, resmng.UNION_MODE.ADD,{propid=e.propid,name=e.name})
    return true
end

function remove(e)
    local u = unionmng.get_union(e.uid)
    if not u then return end

    local bcc = resmng.get_conf("prop_world_unit",e.propid) or {}
    if not bcc then return false end

    if e.state == BUILD_STATE.CREATE then
        local tr = troop_mng.get_troop(e.my_troop_id)
        if tr then tr:back() end
        del(e)
        u:notifyall(resmng.UNION_EVENT.BUILD_SET, resmng.OPERATOR.DELETE, e)
        return
    end

    if is_union_miracal(e.propid) then
        union_build_t.buf_close( e )
        local tr = troop_mng.get_troop(e.my_troop_id)
        if tr then tr:back() end
        del(e)

        local dels = {}
        for k, v in pairs(u.build) do
            local cc = resmng.get_conf("prop_world_unit",v.propid)
            if cc and (not is_union_miracal(v.propid)) then
                if not u:can_castle(v.x,v.y,cc.Size/2) then 
                    table.insert( dels, v )
                end
            end
        end
        if #dels > 0 then
            for _, v in pairs( dels ) do
                remove( v )
            end
        end

    elseif is_union_superres(e.propid) then
        if type(e.my_troop_id)=="table" then
            local count = #( e.my_troop_id or {} )
            if count > 0 then
                for i = count, 1, -1 do
                    local tid = e.my_troop_id[ i ]
                    local troop = troop_mng.get_troop( tid )
                    if troop then
                        troop:gather_gain(e)
                        troop:back()
                    end
                end
            end
        end
        del(e)

    elseif is_union_restore(e.propid) then
        e.state = BUILD_STATE.DESTROY
        local f = false
        for _, v in pairs(u.build ) do
            if is_union_restore(v.propid) and v.state == BUILD_STATE.WAIT then
                f = true 
                break
            end
        end

        if not f then
            local mems = u:get_members()
            for _, ply in pairs( mems or {} ) do
                local node = ply._union and ply._union.restore_sum
                if node then
                    local total = 0
                    local gains = {}
                    for mode, num in pairs( node ) do
                        if num > 0 then
                            table.insert( gains, { "res", mode, num } )
                            total = total + num
                        end
                    end

                    if total > 0 then
                        ply._union.restore_sum = {0,0,0,0}
                        gPendingSave.union_member[ ply.pid ].restore_sum = {0,0,0,0}

                        local troop = troop_mng.create_troop(TroopAction.GetRes, ply, e)
                        troop:settle()
                        troop.curx, troop.cury = get_ety_pos( e )
                        troop:add_goods( gains, VALUE_CHANGE_REASON.REASON_UNION_GET_RESTORE )
                        troop:back()
                    end
                end
            end
        end
        del(e)
        u:ef_init()

    else
        del(e)
    end
end


function can_market(u,pid,r)--能否取出
    for _, v in pairs(u.market or {}) do
        if v.pid == pid then
            for _, vv in pairs(r or {}) do
                for i = 1, #r do
                    if r.propid and (not vv.res[i]) and (r[i] > vv.res[i]) then return false end
                end
            end
        end
    end
    return true
end


function get_restore_limit(p,dp)--计算军团仓库上限
    local pack = { sum = {},day={} }

    local u = unionmng.get_union(p.uid)
    if not u then ack(p, "get_eye_info", resmng.E_NO_UNION) return end

    pack.day.limit = p:get_val("CountDailyStore")
    pack.sum.limit = p:get_val("CountUnionStore")
    pack.day.num   = p:get_res_day()
    pack.sum.num   = p:get_res_count()

    return pack
end

function can_troop(action, p, eid, res)--行军队列发出前判断
    local dp = get_ety(eid)
    if not dp then return false end
    if not is_union_building(dp) then return false end

    local cc = resmng.get_conf("prop_world_unit",dp.propid) or {}
    if not cc then return false end

    if action == TroopAction.SiegeUnion then
        if p.uid ~= dp.uid then
            if is_union_miracal(dp.propid) then return true end
        end
        return false
    end

    if dp.uid ~= p.uid then return false end

    if action == TroopAction.UnionBuild or action == TroopAction.UnionFixBuild or action == TroopAction.UnionUpgradeBuild then
        local total = 0
        for _, v in pairs(res.live_soldier or {}) do
            total = total + v
        end
        local sum,max = p:get_hold_limit(dp)
        if sum <= max then
            if max - sum < total then
                Rpc:tips(p,1,resmng.UNION_HOLD_OVER,{ total-max + sum})
            else 
                return true 
            end
        else 
            Rpc:tips(p,1,resmng.UNION_HOLD_MAX,{}) 
        end
        return false
    end

    if dp.state ~= BUILD_STATE.WAIT then return false end

    if action == TroopAction.HoldDefense then
        if not is_union_miracal( dp.propid ) then return false end
        local t = troop_mng.get_troop(dp.my_troop_id)
        if t then
            for pid, _ in pairs(t.arms or {} ) do
                if pid == p.pid then return false end
            end
        end

        local total = 0
        for k, v in pairs(res.live_soldier or {}) do
            total = total + v
        end
        local sum,max = p:get_hold_limit(dp)

        if sum <= max then
            if max - sum < total then
                Rpc:tips(p,1,resmng.UNION_HOLD_OVER,{ total-max + sum})
            else 
                return true 
            end
        else
            Rpc:tips(p,1,resmng.UNION_HOLD_MAX,{})
        end

    elseif action == TroopAction.Gather then
        if not is_union_superres(dp.propid) then return false end
        for _, id in pairs(p.busy_troop_ids or {} ) do
            local t = troop_mng.get_troop(id)
            local e = get_ety(t.target_eid)
            if not t then return false end
            if not e then return false end
            if is_union_superres(e.propid) and t:get_base_action() == action then return false end
        end
        return true
    
    elseif action == resmng.TroopAction.SaveRes then
        if not is_union_restore(dp.propid) then return false end

        --仓库上限
        local d = get_restore_limit(p,dp)
        local sum = 0
        for k, num in pairs( res ) do
            sum = sum + calc_res(k,num)
        end
        if sum + d.sum.num > d.sum.limit then
            INFO( "[UNION]SaveRes, pid=%d, sum = %d, d.sum.num = %d, d.sum.limit = %d", p.pid, sum, d.sum.num, d.sum.limit )
            return false
        end

        if sum + d.day.num > d.day.limit then
            INFO( "[UNION]SaveRes, pid=%d, sum = %d, d.day.num = %d, d.day.limit = %d", p.pid, sum, d.day.num, d.day.limit )
            return false
        end
        return true

    elseif action == TroopAction.GetRes then
        if not is_union_restore(dp.propid) then return false end

        local node = p._union and p._union.restore_sum
        if not node then return false end
        for mode, num in pairs( res ) do
            if num > 0 then
                if not node[ mode ] then return false end
                if node[ mode ] < num then return false end
            end
        end
        return true

    end
    return false
end

function can_ef(build,ply) --奇迹内
    if build.uid == ply.uid then
        local c = resmng.get_conf("prop_world_unit", ply.propid) or {}
        local cc = resmng.get_conf("prop_world_unit", build.propid) or {}
        
        local offx = math.abs( ( ply.x + c.Size * 0.5 ) - ( build.x + cc.Size * 0.5 ) )
        local offy = math.abs( ( ply.y + c.Size * 0.5 ) - ( build.y + cc.Size * 0.5 ) )
        return math.max( offx, offy ) < ( ( c.Size + cc.Size ) * 0.5 + cc.Range )
    end
end

function is_in_range( miracal, ply )
    local c = resmng.get_conf("prop_world_unit", ply.propid) or {}
    local cc = resmng.get_conf("prop_world_unit", miracal.propid) or {}

    local offx = math.abs( ( ply.x + c.Size * 0.5 ) - ( miracal.x + cc.Size * 0.5 ) )
    local offy = math.abs( ( ply.y + c.Size * 0.5 ) - ( miracal.y + cc.Size * 0.5 ) )
    return math.max( offx, offy ) < ( ( c.Size + cc.Size ) * 0.5 + cc.Range )
end


function save(obj)
    if is_union_building(obj) then
        obj.holding = is_hold(obj)
        gEtys[obj.eid] = obj
        if obj.state ~= BUILD_STATE.DESTROY then
            etypipe.add(obj)
        end
        gPendingSave.union_build[obj._id] = obj
        local u = unionmng.get_union(obj.uid)
        if u then
            u.build[obj.idx] = obj
            u:notifyall(resmng.UNION_EVENT.BUILD_SET, resmng.OPERATOR.UPDATE, obj)
        end
    end
end

function del(e)
    if is_union_building(e) then
        local u = unionmng.get_union(e.uid)
        if not u then return end
        if is_union_superres(e.propid) then
            u.build[e.idx] = nil
            gPendingDelete.union_build[e._id] = 0
        else
            e.state = BUILD_STATE.DESTROY
            u.build[e.idx] = e
            gPendingSave.union_build[e._id] = e
        end
        rem_ety( e.eid )
    end
end

function buf_open(e)--奇迹生成
    local c = resmng.get_conf("prop_world_unit", e.propid)
    if is_union_miracal(e.propid) then
        local es = get_around_eids( e.eid, c.Range )
        if not es then return end
        for _, eid in pairs( es ) do
            local ply = get_ety( eid )
            if ply and is_ply( ply ) then
                if is_in_range(e, ply ) then
                    local tmp = get_ety( ply.ef_eid )
                    if tmp and tmp.sn < e.sn then

                    else
                        print( "buf_open, pid, eid", ply.pid, e.eid )
                        ply.ef_eid = e.eid
                        task_logic_t.process_task(ply, TASK_ACTION.UNION_CASTLE_EFFECT)
                    end
                end
            end
        end
    end
    local u = unionmng.get_union(e.uid)
    if u then u:ef_init() end
end

function buf_close(e)--奇迹移除
    local c = resmng.get_conf("prop_world_unit", e.propid)
    if is_union_miracal(e.propid) then
        local es = get_around_eids( e.eid, c.Range )
        if not es then return end
        for _, eid in pairs( es ) do
            local ply = get_ety( eid )
            if ply and is_ply( ply ) then
                if ply.ef_eid == e.eid then
                    ply_move( ply, e.eid )
                end
            end
        end
    end
end

function ply_move(ply, ignore)--迁城变奇迹影响
    ply.ef_eid = 0
    local builds = get_around_eids( ply.eid, 25 )
    if not builds then
        task_logic_t.process_task(ply, TASK_ACTION.UNION_CASTLE_EFFECT)
        return
    end

    local x, y = ply.x, ply.y
    local w = 4 -- player castle size

    local sn  = math.huge
    for _, eid in pairs( builds ) do
        if is_union_building(eid) then
            if not ignore or eid ~= ignore then
                local e = get_ety(eid)
                if is_union_miracal(e.propid) then
                    local state = e.state
                    if state == BUILD_STATE.UPGRADE or state == BUILD_STATE.FIX or state == BUILD_STATE.WAIT then
                        if is_in_range( e, ply ) then
                            if e.sn < sn then
                                ply.ef_eid = e.eid
                                sn = e.sn
                            end
                        end
                    end
                end
            end
        end
    end
    if math.huge ~= sn then
        task_logic_t.process_task(ply, TASK_ACTION.UNION_CASTLE_EFFECT)
    end
end


function get_max_hp( obj )
    local obj_id = obj.propid
    if obj.state == BUILD_STATE.UPGRADE then
        local c = resmng.get_conf("prop_world_unit",obj.propid)
        if c then
            local id  = union_buildlv.get_buildlv(obj.uid, c.BuildMode).id
            if id then
                local cc = resmng.get_conf("prop_union_buildlv",id)
                if cc then
                    if c.Lv < cc.Lv then obj_id = obj.propid - c.Lv + cc.Lv  end
                end
            end
        end
    end
    local maxhp = resmng.get_conf("prop_world_unit", obj_id).Hp
    return maxhp, obj_id
end


function fire( obj, s )
    local secs = 1800
    if is_timer_valid( obj, obj.tmSn_f ) then
        obj.tmOver_f = obj.tmOver_f + secs
        timer.adjust( obj.tmSn_f, obj.tmOver_f )
    else
        obj.tmStart_f = gTime
        obj.tmOver_f = gTime + secs
        obj.tmSn_f = timer.new( "union_build_fire", secs, obj.eid )
    end
    recalc_build( obj )
end


function build_complete( obj )
    local propid = obj.propid
    if obj.state == BUILD_STATE.UPGRADE then 
        propid = obj.toid 
        obj.toid = nil
    end

    local conf = resmng.get_conf( "prop_world_unit", propid )
    if conf then
        obj.propid = conf.ID
        obj.hp = conf.Hp
        if is_timer_valid( obj, obj.tmSn_b ) then timer.del( obj.tmSn_b ) end
        obj.tmSn_b = 0
        obj.tmStart_b = 0
        obj.tmOver_b = 0
        obj.speed_b = 0
        obj.state = BUILD_STATE.WAIT

        local troop = get_home_troop( obj )
        if troop then
            if is_union_miracal( propid ) then
                troop.action = TroopAction.HoldDefense + 200
                troop.tmStart = 0
                troop.tmOver = 0

                local chg = gPendingSave.troop[ troop._id ]
                chg.action = troop.action
                chg.tmStart = troop.tmStart
                chg.tmOver = troop.tmOver
                troop:do_notify_owner( chg )
                buf_open( obj )
                local u = unionmng.get_union( obj.uid )
                if u.build_first2 ~= 1  then
                    for _, p in pairs(u._members) do
                        p:send_union_build_mail(resmng.MAIL_10075, {}, {})
                        p:send_union_build_mail(resmng.MAIL_10076, {}, {})
                    end
                    u.build_first2 = 1  
                end
            else
                troop:back()
                obj.my_troop_id = 0
            end
        end

        if is_union_superres( obj.propid ) then
            obj.my_troop_id = {}
            local conf = resmng.get_conf( "prop_world_unit", obj.propid )
            if conf then
                obj.val = conf.Count
            end
        end

        if is_union_restore( obj.propid ) then
            local u = unionmng.get_union( obj.uid )
            if u then u:ef_init() end
        end

        if is_firing( obj ) then
            recalc_build( obj ) -- be careful not to loop recursion
        else
            save( obj )
        end
    end
end

function is_building( obj )
    local state = obj.state
    local conf = BUILD_STATE
    return state == conf.CREATE or state == conf.UPGRADE or state == conf.FIX
end

function is_firing( obj )
    return obj.tmOver_f > gTime
end

function calc_speed_build( obj )
    local speed = 0
    local troop = get_home_troop( obj )
    if troop then
        local pow = 0
        local prop_arm = resmng.prop_arm
        for pid, arm in pairs( troop.arms or {} ) do
            local sum = 0
            for id, num in pairs( arm.live_soldier or {} ) do
                if num > 0 then
                    sum = sum + num
                    local conf = prop_arm[ id ]
                    if conf then
                        pow = pow + conf.Pow * num 
                    end
                end
            end
        end

        if pow > 0 then
            local conf = resmng.get_conf( "prop_world_unit", obj.propid )
            if conf then
                speed = pow * ( conf.Speed or 0 ) / ( 1000 * 10000 )
            end
        end
    end
    return speed
end

function calc_speed_gather( obj )
    local speed = 0
    local ids = obj.my_troop_id
    if ids then
        if type( ids ) == "number" then
            ids = { ids }
            obj.my_troop_id = ids
        end

        for _, tid in pairs( ids ) do
            local troop = troop_mng.get_troop( tid )
            if troop then
                speed = speed + troop:get_extra( "speed" ) or 0
            end
        end
    end
    return speed
end


function is_timer_valid( obj, tsn )
    if tsn and tsn > 0 then
        local node = timer.get( tsn )
        if node and node.param[ 1 ] == obj.eid then return true end
    end
end

function is_hp_full( obj )
    if is_building( obj  ) then
        return false

    elseif is_firing( obj ) then
        return false

    else
        local maxhp = get_max_hp( obj )
        return obj.hp >= maxhp
    end
end


function calc_dura( count, speed )
    if count < 0 then count = count * (-1) end
    if speed < 0 then speed = speed * (-1) end

    local dura 
    if speed > 0 then
        dura = count / speed
    else
        dura = SECS_TWO_WEEK
    end
    if dura > SECS_TWO_WEEK then return SECS_TWO_WEEK end
    if dura < 1 then return 1 end
    return math.ceil( dura )
end


function recalc_gather( obj )
    if obj.state ~= BUILD_STATE.WAIT then return end
    if not is_union_superres( obj.propid ) then return end

    local speed_g = calc_speed_gather( obj )
    
    if obj.speed_g == 0 then
        obj.speed_g = speed_g
        obj.tmStart_g = gTime
    end

    local delta = 0
    if obj.speed_g > 0 then
        delta = obj.speed_g * ( gTime - obj.tmStart_g )
        obj.tmStart_g = gTime
    end

    local val = obj.val - delta
    if val < 0 then val = 0 end
    obj.val = val
    obj.speed_g = speed_g

    if val == 0 then
        remove( obj )
        return
    end

    local dura = 0
    if speed_g > 0 then
        dura = math.ceil( obj.val / speed_g )
        obj.tmStart_g = gTime
        obj.tmOver_g = gTime + dura
        if is_timer_valid( obj, obj.tmSn_g ) then
            timer.adjust( obj.tmSn_g, obj.tmOver_g )
        else
            obj.tmSn_g = timer.new( "union_gather_empty", dura, obj.eid )
        end
    else
        obj.tmStart_g = 0
        obj.tmOver_g = 0
        if is_timer_valid( obj, obj.tmSn_g ) then timer.del( obj.tmSn_g ) end
        obj.tmSn_g = 0
    end

    save( obj )
end


function recalc_build( obj )
    --if not is_building( obj) and not is_firing( obj ) then return end
    
    local speed_f = 0
    if is_firing( obj ) then speed_f = 0.5 end

    local speed_b = 0
    if is_building( obj ) then speed_b = calc_speed_build( obj ) end

    if obj.speed_b == 0 and obj.speed_f == 0 then
        if speed_f > 0 then
            obj.speed_f = speed_f
            obj.tmStart_f = gTime
        end

        if speed_b > 0 then
            obj.speed_b = speed_b
            obj.tmStart_b = gTime
        end
        
        if obj.state == BUILD_STATE.UPGRADE then
            obj.tohp, obj.toid = get_max_hp( obj )
        else
            local conf = resmng.get_conf( "prop_world_unit", obj.propid )
            obj.tohp, obj.toid = conf.Hp, nil
        end
    end

    local delta = 0
    if obj.speed_b > 0 then 
        delta = obj.speed_b * ( gTime - obj.tmStart_b ) 
        obj.tmStart_b = gTime
    end

    if obj.speed_f > 0 then 
        delta = delta - obj.speed_f * ( gTime - obj.tmStart_f )
        obj.tmStart_f = gTime
    end

    local hp = obj.hp + delta
    if player_t.debug_tag then hp = obj.tohp end
    if hp > obj.tohp then hp = obj.tohp end
    if hp < 0 then hp = 0 end

    obj.hp = hp
    obj.speed_b = speed_b
    obj.speed_f = speed_f

    print( "union_build", hp )

    if hp == 0 then
        remove( obj )
        return
    elseif hp >= obj.tohp then
        if is_building( obj ) then 
            build_complete( obj ) 
            return
        end
    end

    local speed = speed_b - speed_f
    local dura = 0
    if speed > 0 then
        dura = math.ceil( ( obj.tohp - obj.hp ) / speed )

    elseif speed < 0 then
        dura = math.ceil( obj.hp / (-1 * speed ) )

    else
        dura = SECS_TWO_WEEK

    end
        
    if speed_b > 0 then
        obj.tmStart_b = gTime
        obj.tmOver_b = gTime + dura
    else
        obj.tmStart_b = 0
        obj.tmOver_b = 0
    end

    if speed_f > 0 then
        obj.tmStart_f = gTime
    else
        obj.tmStart_f = 0
        obj.tmOver_f  = 0
    end

    if is_timer_valid( obj, obj.tmSn_b ) then
        if speed ~= 0 then
            timer.adjust( obj.tmSn_b, obj.tmOver_b )
        else
            timer.del( obj.tmSn_b )
            obj.tmSn_b = 0
        end
    else
        if speed ~= 0 then
            obj.tmSn_b = timer.new( "union_build_construct", dura, obj.eid )
        end
    end

    if is_building( obj ) then
        local troop = get_home_troop( obj )
        if troop then
            troop.tmOver = obj.tmOver_b
            local chg = gPendingSave.troop[ troop._id ]
            chg.tmOver = troop.tmOver
            troop:do_notify_owner( {tmOver=troop.tmOver} )
        end
    end
    save( obj )
end




function try_hold_troop( obj, troop )
    local sum, max = 0, 0
    local u = unionmng.get_union(obj.uid)
    if not u then return end

    local max = get_hold_limit( obj )
    local num = troop:get_troop_total_soldier()

    local tr = troop_mng.get_troop(obj.my_troop_id)
    local dtroop = tr
    if tr then 
        sum = tr:get_troop_total_soldier() 
    else
        tr = {}
    end

    local left = max - sum
    if left <= 0 then
        return false
    elseif left > num then
        troop:split_tr_by_num_and_back(0, tr )
    else
        troop:split_tr_by_num_and_back(num-left, tr )
    end

    if dtroop then
        troop:merge( dtroop ) 
    else
        obj.my_troop_id = troop._id
        save( obj )
    end
    return true
end


function get_hold_limit( dest )
    local u = unionmng.get_union( dest.uid )
    if u then
        local c = resmng.get_conf("prop_world_unit", dest.propid)
        if c then
            return get_val_by("CountGarrison", u:get_ef(), c.Buff )
        else
            return get_val_by("CountGarrison", u:get_ef())
        end
    end
    return 0
end
