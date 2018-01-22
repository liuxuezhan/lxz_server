
local OnRpc = {}

function OnRpc.first_packet_ack( p, code )
    if code == 8 then
        local info = {}
        local idx = p.idx
        info.server_id = p.map or config.Map

        local cival = p.cival
        if not cival then
            cival = ( idx % 4 )
            if cival == 0 then cival = 4 end
        end
        info.cival = cival 

        info.pid = -1 
        info.token_expire = gTime + 36000
        info.extra = ""
        info.time = gTime
        info.token = c_md5( p.account )
        info.open_id = p.account
        info.did = "robot_" .. idx

        info.signature = c_md5( APP_KEY .. tostring( info.token_expire ) .. info.extra .. tostring( info.time ) .. info.token .. info.open_id )
        info.version = 10000000
        info.info = { vGameAppid="NULL" }

        Rpc:firstPacket( p, p.map or config.Map, info )
    end
end

function OnRpc.onLogin( p, pid, name )
    p.action = "player"
    p.pid = pid
    p.name = name
    p.online = gTime
    gPlys[ pid ] = p

    --p.tmStart = c_msec()

    Rpc:getTime(p,1)
    LOG( "onLogin", pid )

    --if type( name ) == "number" then
    --    local chg_name = make_name.make_name()
    --    if name ~= chg_name then
    --        change_name( p, chg_name )
    --    end
    --end
end

function OnRpc.getTime( p,tag,tm,sm)
    p.stm = tm - gTime
end


gCountLoadData = 0
function OnRpc.loadData( p, info )
    local key = info.key
    local val = info.val
    if key == "pro" then
        for k, v in pairs( val ) do
            p[ k ] = v
        end

        gCountLoadData = gCountLoadData + 1
        if gCountLoadData % 100 == 0 then
            WARN( "USE_TIME, count=%d, use=%d", gCountLoadData, c_msec() - gActionStart )
        end

    elseif key == "build" then
        local bs = {}
        for k, v in pairs( val ) do
            bs[ v.idx ] = v
        end
        p._build = bs

    elseif key == "troop" then
        p._troop = {}
        for _, v in pairs( val ) do
            p._troop[ v._id] = v
        end
    elseif key == "done" then
        --gCountLoadData = gCountLoadData + 1
        --if gCountLoadData % 100 == 0 then
        --    WARN( "USE_TIME, count=%d, use=%d", gCountLoadData, c_msec() - gActionStart )
        --end

    else
        p[ "_" .. key ] = val
    end
end


function OnRpc.stateItem( p, info )
    if not p._item then p._item = {} end
    for k, v in pairs( info ) do
        local idx = v[1]
        local node = p._item[ idx ]
        if not node then
            p._item[ idx ] = v
        else
            for ik, iv in pairs( v ) do
                node[ ik ] = iv
            end
        end
    end
    if p.eventItemUpdated then
        p.eventItemUpdated(p)
    end
end

function OnRpc.equip_add(p, info)
    if not p._equip then p._equip = {} end
    p._equip[info._id] = info
    if p.eventEquipAdd then
        p.eventEquipAdd(p, info)
    end
end

function OnRpc.equip_rem(p, id)
    if p._equip then
        p._equip[id] = nil
    end
    if p.eventEquipRem then
        p.eventEquipRem(p, id)
    end
end

function OnRpc.stateBuild( p, info )
    if not p._build then p._build = {} end
    local build = p._build[ info.idx ]
    if build then
        for k, v in pairs( info ) do
            build[ k ] = v
        end
        if p.eventBuildUpdated then
            p.eventBuildUpdated(p, build)
        end
    else
        p._build[ info.idx ] = info
        if p.eventNewBuild then
            p.eventNewBuild(p, info)
        end
    end
end

local pro_event = {
    tech = "eventTechUpdated",
    bufs = "eventBufUpdated",
    genius = "eventGeniusUpdated",
    sinew = "eventSinewUpdated",
    uid = "eventUnionIdChanged",
    build_queue = "eventBuildQueueUpdated",
    task_target_all_award_index = "eventTargetAwardIndexUpdated",
    activity = "eventActivityUpdated",
    activity_box = "eventActivityBoxUpdated",
    hero_road_cur_chapter = "eventCurHeroRoadUpdated",
    hero_road_chapter = "eventHeroRoadUpdated",
    hurts = "eventHurtsUpdated",
    cures = "eventCuresUpdated",
    field = "eventFieldUpdated",
    lv = "eventRoleLevelUpdated",
    name = "eventRoleNameUpdated",
}

function OnRpc.statePro( p, info )
    for k, v in pairs( info ) do
        local old_value = p[ k ]
        p[ k ] = v

        local event_name = pro_event[ k ]
        if event_name then
            if p[event_name] then
                p[event_name](p, v, old_value)
            end
        end
    end
end

function OnRpc.sync( p, sn )
    if not p.sn or sn >= p.sn then
        p.sn = sn
    end

    if p._sync_func then
        local sns = {}
        for k, v in pairs(p._sync_func) do
            if k <= sn then
                table.insert(sns, k)
            end
        end
        for _, sn in pairs(sns) do
            p._sync_func[sn](p, sn)
            p._sync_func[sn] = nil
        end
    end
end

function OnRpc.fightInfo(p, info)
    if p.eventFightInfo then
        p.eventFightInfo(p, info)
    end
end

function OnRpc.stateTroop( p, info )
    local id = info._id
    if not p._troop then p._troop = {} end
    if info.delete then
        p._troop[ id ] = nil
        if p.eventTroopDeleted then
            p.eventTroopDeleted(p, id)
        end
    else
        --p._troop[ id ] = info 
        local troop = p._troop[ id ]
        if nil ~= troop then
            for k, v in pairs(info) do
                troop[k] = v
            end
        else
            p._troop[ id ] = info
            troop = info
        end
        if p.eventTroopUpdated then
            p.eventTroopUpdated(p, id, troop)
        end
    end
end

function OnRpc.stateHero( p, info )
    if not p._hero then p._hero = {} end
    local node = p._hero[ info.idx ]
    if node then
        for k, v in pairs( info ) do
            node[ k ] = v 
        end
        if p.eventHeroUpdated then
            p.eventHeroUpdated(p, node)
        end
    else
        p._hero[ info.idx ] = info
        if p.eventNewHero then
            p.eventNewHero(p, info)
        end
    end
end

function OnRpc.addEty( p, info )
    if not p._etys then p._etys = {} end
    local obj = etypipe.parse( info )
    p._etys[ obj.eid ] = obj
    p._tick_add_ety = c_msec()
    if p.eventNewEntity then
        p.eventNewEntity(p, obj)
    end
end


function OnRpc.addEtys( p, info )
    for k, v in pairs( info ) do
        OnRpc.addEty( p, v )
    end
    p._tick_add_ety = c_msec()
    if p.eventNewEntities then
        p.eventNewEntities(p)
    end
end

function OnRpc.remEty(p, eid)
    local obj = p._etys[eid]
    if nil == obj then
        return
    end
    p._etys[eid] = nil
    if p.eventDelEntity then
        p.eventDelEntity(p, obj)
    end
end

function OnRpc.upd_arm( p, info )
    p._arm = info
    if p.eventArmyUpdated then
        p.eventArmyUpdated(p, info)
    end
end

function OnRpc.get_city_for_robot_ack(p, mode, eid)
    if mode == ACT_NAME.NPC_CITY then
        p.npc_eid = eid
    end
    if mode == ACT_NAME.KING then
        p.king_eid = eid
    end
    if mode == ACT_NAME.LOST_TEMPLE then
        p.lt_eid = eid
    end
end

function OnRpc.onError(p, cmd_hash, code, reason)
    local rpcf = Rpc.remoteF[cmd_hash]
    if nil == rpcf then
        return
    end
    if p.eventRpcError then
        p.eventRpcError(p, rpcf, code, reason)
    end
end

function OnRpc.union_list(p, key, unions)
    if p.eventGotUnionList then
        p.eventGotUnionList(p, key, unions)
    end
end

function OnRpc.union_reply(p, union_id, name, state)
    if p.eventUnionReply then
        p.eventUnionReply(p, union_id, name, state)
    end
end

function OnRpc.union_on_create(p,pack)
    p.uid = pack.uid
    if not _us then _us = {}  end
    _us[p.uid] = pack
    _us[p.uid].build = {}
end

function OnRpc.union_help_get(p, helps)
    if p.eventUnionHelpGet then
        p.eventUnionHelpGet(p, helps)
    end
end

function OnRpc.msg_load(p, what, sn, count, new, info)
    if what=="black_market" then
        lxz(info)
    end
end
function OnRpc.union_load(p,pack)
    if not _us then _us = {}  end
    if not _us[p.uid] then _us[p.uid] = {}  end
    u = _us[p.uid] 
    if pack.key == "info" then
        --u = pack.val
        for k, v in pairs(pack.val) do
            u[k] = v
        end
    elseif pack.key == "ply" then
    elseif pack.key == "member" then
        for _, v in pairs( pack.val or {} ) do
            --local t = rpchelper.decode_rpc(v,"unionmember")
            if not u.member then u.member = {} end
            u.member[v.pid] = t
        end
    elseif pack.key == "apply" then
        u._apply = pack.val
    elseif pack.key == "mass" then elseif pack.key == "aid" then
    elseif pack.key == "tech" then
        p.utech = p.utech or {}
        for k, v in pairs(pack.val.info) do
            p.utech[v.idx] = v
        end
    elseif pack.key == "donate" then
        p.donate = pack.val
    elseif pack.key == "union_donate" then
        lxz(pack.val)
        p.union_donate = pack.val
    elseif pack.key == "fight" then--room
    elseif pack.key == "build" then
        p.buildlv = {} 
        --lxz(pack)
        for k, v in pairs(pack.val) do
            if k == "build" then
                u.build = u.build or {}
                for _, v in pairs(pack.val.build or {} ) do
                    u.build[v.idx] = v 
                end
            else
                p.buildlv[k]=v
            end
        end

    elseif pack.key == "mall" then
    elseif pack.key == "item" then
    elseif pack.key == "word" then
        u.word = pack.val
    elseif pack.key == "relation" then
    elseif pack.key == "mars" then
        p.mars = pack.val
    elseif pack.key == "enlist" then
    elseif pack.key == "ef" then
    end
    if p.eventUnionLoaded then
        p.eventUnionLoaded(p, pack.key, u)
        p.eventUnionLoaded.__debug = nil
    end
end

function OnRpc.union_member_get(p, uid, members)
    for k, v in pairs(members) do
        if v.pid == p.pid then
            p.union_member = p.union_member or {}
            local union_member = p.union_member 
            for mk, mv in pairs(v) do
                union_member[mk] = mv
            end
        end
    end
end

local union_broadcast_events = {
    [UNION_EVENT.INFO] =
    {
        [UNION_MODE.UPDATE] = "eventUnionInfoUpdated",
    },
    [UNION_EVENT.MEMBER] = 
    {
        [UNION_MODE.ADD] = "eventAddUnionMember",
    },
    [UNION_EVENT.HELP] = 
    {
        [UNION_MODE.ADD] = "eventUnionHelpAdd",
        [UNION_MODE.DELETE] = "eventUnionHelpDel",
    },
    [UNION_EVENT.BUILD_SET] =
    {
        [OPERATOR.UPDATE] = "eventUnionBuildUpdated",
    },
}

function OnRpc.union_broadcast(p,key,mode,data)
    _us = _us or {}
    if key == "build_set" then
--        lxz(mode,data)
        if mode == resmng.OPERATOR.UPDATE then 
            _us[p.uid].build[data.idx] = data
        elseif mode == resmng.OPERATOR.DELETE then 
            _us[p.uid].build[data.idx] = nil
        end
    elseif key == UNION_EVENT.INFO then
        if mode == UNION_MODE.UPDATE then
            _us[data.uid] = _us[data.uid] or {}
            local u = _us[data.uid]
            for k, v in pairs(data) do
                u[k] = v
            end
        end
    elseif key == UNION_EVENT.MEMBER then
        if data.pid == p.pid then
            if mode == UNION_MODE.ADD or
                mode == UNION_MODE.UPDATE or
                mode == UNION_MODE.RANK_UP or
                mode == UNION_MODE.RANK_DOWN then
                local member = p.union_member
                if member then
                    for k, v in pairs(data) do
                        member[k] = v
                    end
                else
                    p.union_member = data
                end
            elseif mode == UNION_MODE.DELETE then
                p.union_member = nil
            end
        end
    end
    local events = union_broadcast_events[key]
    if nil ~= events then
        local event_name = events[mode]
        if nil ~= event_name then
            local handler = p[event_name]
            if nil ~= handler then
                handler(p, data)
            end
        end
    end
end

function OnRpc.ack_troop_info(p, info)
    local count = 0
    for k, arm in pairs(info.arms or {}) do
        for _, num in pairs(arm) do
            count = count + num
        end
    end
    p.arm_count = count
end

function OnRpc.finish_task_resp(p, ret)
    p.task_resp = ret
end

function OnRpc.update_task_info(p, info)
    if nil == p._task then
        return
    end

    for _, v in ipairs(info) do
        local old_task = nil
        for k, v1 in pairs(p._task.cur or {}) do
            if v.task_id == v1.task_id then
                p._task.cur[k] = v
                old_task = v1
                break
            end
        end
        if TASK_STATUS.TASK_STATUS_FINISHED == v.task_status then
            if TASK_TYPE.TASK_TYPE_TRUNK == v.task_type or
                TASK_TYPE.TASK_TYPE_BRANCH == v.task_type then
                for k, t in pairs(p._task.cur) do
                    if t.task_id == v.task_id then
                        p._task.cur[k] = nil
                        break
                    end
                end
                table.insert(p._task.finish, v.task_id)
            end
        end
        if nil == old_task then
            table.insert(p._task.cur, v)
        end
        if p.eventTaskInfoUpdated then
            p:eventTaskInfoUpdated(v, old_task)
        else
        end
    end
end

function OnRpc.union_task_get(p, info)
    p.union_task = info
end

function OnRpc.get_can_atk_citys_ack(p,info)
    p.city_propid = {}
    if not _npc then 
        Rpc:get_npc_map_req(p)
        wait_for_ack( p, "get_npc_map_ack")
    end
    for _, propid in pairs(info.can_atk_citys or {}) do
        table.insert(p.city_propid,propid)
    end
end

function OnRpc.get_npc_map_ack(p,info)
    _npc = {} 
    for _, v in pairs(info.map or {}) do
        _npc[v[4]]={ eid = v[1], propid=v[4] }
    end
end

function OnRpc.get_buff(p,k,v)
    if not p.buf then  p.buff = {} end
    p.buff[k] = v
end

function OnRpc.gen_boss_eid_ack(p, eid)
    p.boss_eid = eid
end

function OnRpc.get_eye_info(p, eid, info)
    p.eye_info = info
    if p.eventEyeInfo then
        p.eventEyeInfo(p, eid, info)
    end
end

function OnRpc.ety_info_ack(p, info)
    p.ety_info = info
end

function OnRpc.union_tech_info(p, info)
    p.union_tech_info = info

    p.utech = p.utech or {}
    local tech = p.utech[info.idx]
    if nil ~= tech then
        for k, v in pairs(info) do
            tech[k] = v
        end
    else
        tech = info
        p.utech[info.idx] = tech
    end

    if p.eventUnionTechInfo then
        p.eventUnionTechInfo(p, tech)
    end
end

function OnRpc.union_donate_info(p, info)
    --p.union_donate_info = info
    p.donate = info
    if p.eventUnionDonateInfo then
        p.eventUnionDonateInfo(p, info)
    end
end
function OnRpc.union_buildlv_donate(p, info)
    p.union_buildlv_donate = info

    local prop = resmng.prop_union_buildlv[info.id]
    p.buildlv = p.buildlv or {}
    p.buildlv.buildlv = p.buildlv.buildlv or {}
    p.buildlv.buildlv[prop.Mode] = info
    p.buildlv.log[prop.Mode].tm = gTime

    if p.eventUnionBuildlvDonate then
        p.eventUnionBuildlvDonate(p, info)
    end
end

function OnRpc.union_mission_get(p,info)
    p.utask = info
end

function OnRpc.dbg_show( p, info )
    local obj = info.ack
    local func = function ( ... )
        local str = string.format( ... )
        print( str )
    end

    if type( obj ) == "table" then
        doDumpTab( obj, nil, 20, 0, true, func )
    else
        print( obj )
    end
end

function OnRpc.get_characters( p, info )
    dumpTab( info, "get_characters" )
end



function OnRpc.ping( p )
    Rpc:ping(p)
end

function OnRpc.ache_info_ack(p, info)
    p._ache = p._ache or {}
    p._ache.count = info.count
    p._ache.ache = info.ache
    p._ache.ache_point = info.ache_point
    if p.eventAcheInfoUpdated then
        p.eventAcheInfoUpdated(p, p._ache)
    end
end

function OnRpc.set_ache(p, idx, time)
    p._ache = p._ache or {}
    p._ache.ache = p._ache.ache or {}

    p._ache.ache[idx] = time
    if p.eventAcheUpdated then
        p.eventAcheUpdated(p, idx, time)
    end
end

function OnRpc.set_count(p, id, count)
    p._ache = p._ache or {}
    p._ache.count = p._ache.count or {}

    p._ache.count[id] = count
    if p.eventAcheCountUpdated then
        p.eventAcheCountUpdated(p, id, count)
    end
end

function OnRpc.display_ntf(p, pack)
    if p.eventDisplayNotify then
        p.eventDisplayNotify(p, pack)
    end
end

function OnRpc.mail_load(p, mails)
    if p.eventMailLoad then
        for k, v in pairs(mails) do
            p.eventMailLoad(p, v)
        end
    end

    if 0 == #mails and p.eventAllMailLoaded then
        p.eventAllMailLoaded(p)
    end
end

function OnRpc.mail_notify(p, mails)
    if p.eventNewMail then
        for k, v in pairs(mails) do
            p.eventNewMail(p, v)
        end
    end
end

function OnRpc.mail_fetch_resp(p, sns)
    if p.eventMailFetchResponse then
        p.eventMailFetchResponse(p, sns)
    end
end

function OnRpc.npc_info_by_propid_ack(p, info)
    if p.eventNpcInfoByPropid then
        p.eventNpcInfoByPropid(p, info)
    end
end

function OnRpc.certify( p, code )
    print( "OnCertify", code )
end


return OnRpc

