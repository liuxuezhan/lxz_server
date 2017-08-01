module( "agent_t", package.seeall )

function agent_test( self, info, info1)
    pause()
end

function agent_test_struct( self, id, mems, name )
    pause()
    print("ok")
end

function agent_move_eye( self, pid, x, y )
    c_mov_eye(pid, x, y)
end


function agent_remove_eye( self, pid )
    c_rem_eye( pid )
end

function agent_syn_call(self, id, func, arg)
    print("sync all ", id, func, arg)
    local map_id = self.pid
    if arg[1] == "union" then
        local uid = arg[2]
        local union = unionmng.get_union(uid)
        if union then
            table.remove(arg, 1)
            table.remove(arg, 1)
            local val  = union_t[func](union, self.pid, id, unpack(arg))
            if id ~= 0 then
                Rpc:callAgent(map_id, "agent_syn_call_ack", id, val or {})
                return
            end
        end
    elseif arg[1] == "union_relation" then
        local uid = arg[2]
        local union = unionmng.get_union(uid)
        if union then
            table.remove(arg, 1)
            table.remove(arg, 1)
            local val = union_relation.list(union)
            if id ~= 0 then
                Rpc:callAgent(map_id, "agent_syn_call_ack", id, val or {})
                return
            end
        end
    elseif arg[1] == "player" then
        local pid = arg[2]
        local ply = getPlayer(pid)
        if ply then
            table.remove(arg, 1)
            table.remove(arg, 1)
            local val = player_t[func](ply, unpack(arg))
            if id ~= 0 then
                Rpc:callAgent(map_id, "agent_syn_call_ack", id, val or {})
                return
            end
        end
    end

    if id~= 0 then
        Rpc:callAgent(map_id, "agent_syn_call_ack", id, {})
    end

end

function agent_syn_call_ack(self, id, ret)
    --print("sync all back ", id, ret)
    local co = getCoroPend("syncall", id) 
    coroutine.resume(co, ret)
end

function agent_login(self, pid, info)
    local ply = getPlayer(pid)
    if ply then
        ply:login(pid)
        if info then
            ply.token = info.token
            gPendingSave.player[ ply.pid ].token = info.token
            ply.ip = info.ip
            ply.sockid = info.sockid
        end
    end
end

function clear_ply_info(pid)
    local ply = getPlayer(pid)
    if ply then
        local build = ply._build or {}
        for k, v in pairs(build) do
            build_t.clr(v)
        end
        ply._build = nil
    end

    local hero = ply._hero or {}
    for k, v in pairs(hero) do
        hero_t.clr(v)
    end
    ply._hero = nil

    local equip = ply._equip or {}
    for k, v in pairs(equip) do
        v:clr()
        --gPendingSave.equip[ k ] = v
    end
    ply._equip = nil

    local item = ply.item or {}
    gPendingDelete.item[ ply.pid ] = 0
    ply.item = nil

    local count = ply._count or {}
    gPendingDelete.count[ ply.pid ] = 0
    ply._count = nil

    gPendingDelete.title[ ply.pid ] = 0
    gPendingDelete.tit_point[ ply.pid ] = 0

    local ache = ply._ache or {}
    gPendingDelete.ache[ ply.pid ] = 0
    ply._ache = nil

    troop_mng.delete_troop(ply.my_troop_id)

    gPendingDelete.finished_task[ply.pid] = 0
    
    local cur_list = ply:get_cur_task_list()
    for k, v in pairs(cur_list or {}) do
        local _id = ply.pid.."_"..v.task_id
        gPendingDelete.task[_id] = 0
    end
    ply._cur_task_list = nil

    ply.first_blood = nil
    gPendingDelete.first_blood[ply.pid] = 0

    rem_ety(ply.eid)
    remPlayer(ply.pid)
    gOnlines[ ply.pid ] = nil
    gPendingDelete.player[ply.pid] = 0
    rank_mng.rem_person_data(ply.pid)
end

function agent_migrate_ack(self, pid, map, ret)
    if ret ~= -1 then
        local ply = getPlayer(pid)
        if ply then
            pushHead(_G.GateSid, 0, 9)  -- set server id
            pushInt(ply.sockid)
            pushInt(self.pid)
            pushInt(ply.pid)
            pushOver()
            ply.map = self.pid
            local info = {}
            info.token = ply.token
            info.sockid = ply.sockid
            info.ip = ply.ip
            Rpc:callAgent(self.pid, "agent_login", pid, info)
            return
        end
        --local ply = getPlayer(pid)
        --if ply then
        --    local build = ply._build or {}
        --    for k, v in pairs(build) do
        --        build_t.clr(v)
        --    end
        --    ply._build = nil
        --end

        --local hero = ply._hero or {}
        --for k, v in pairs(hero) do
        --    hero_t.clr(v)
        --end
        --ply._hero = nil

        --local equip = ply._equip or {}
        --for k, v in pairs(equip) do
        --    v:clr()
        --    gPendingSave.equip[ k ] = v
        --end
        --ply._equip = nil

        --local item = ply.item or {}
        --gPendingSave.item[ pid ] = nil
        --ply.item = nil

        --local count = ply._count or {}
        --for k, v in pairs(count) do
        --    gPendingSave.count[ ply.pid ][k] = nil
        --end
        --ply._count = nil

        --local ache = ply._ache or {}
        --for k, v in pairs(ache) do
        --    gPendingSave.ache[ ply.pid ][k] = nil
        --end
        --ply._ache = nil

        --local arm = data.arm
        --local troop = troop_mng.create_troop(TroopAction.DefultFollow, ply, ply)
        --ply.my_troop_id = troop._id
        --for id, num in pairs( arm ) do
        --    troop:add_soldier( id, num )
        --end

        --local db = ply:getDb()
        --db.task:delete({_id=ply.pid}) 
    else
        self:add_debug( "can not move" )
    end
end

function change_server( self, pid, x, y, data , timers, union_pro, troop, mails)
    -- 是否有空位    
    local from = self.pid
  --  if c_map_test_pos( x, y, 4 ) ~= 0 then
  --      Rpc:callAgent( from, "change_server_ack", pid, gMapID, -1 ) 
  --      return
  --  end

    local eid = get_eid_ply()
    local pro = data._pro
    local tm_login = pro.tm_login
    pro.eid = eid
    pro.map = gMapID
    pro.emap = gMapID
    local ply = player_t.new( pro )
    ply.x = x
    ply.y = y
    ply.uid = nil
    ply.sockid = data.sockid 
    ply.tm_login = tm_login or gTime
    rawset( ply, "eid", eid )

    local build = data._build or {}
    local bs = {}
    for k, v in pairs( build or {}) do
        b = v._pro
        bs[ b.idx ] = build_t.new( b )
    end
    ply._build = bs

    local hs = {}
    for k, v in pairs(data._hero or {}) do
        h = v._pro
        local hero = hero_t.new(h)
        hs[h.idx] = hero
        heromng.add_hero(hero)
    end
    ply._hero = hs

    local equip = data._equip or {}
    local es = {}
    for k, v in pairs(equip or {}) do
        local id = getId("equip")
        v._id = id
        gPendingSave.equip[ id ] = v
        es[id] = v
    end
    --ply._equip = es

    local item = data._item or {}
    ply._item = {}
    for k, _ in pairs(item) do
        ply:add_item_pend(k)
    end

    local count = data._count or {}
    for k, v in pairs(count or {}) do
        gPendingSave.count[ ply.pid ][k] = v
    end
    --ply._count = count

    local ache = data._ache or {}
    for k, v in pairs(ache or {}) do
        gPendingSave.ache[ ply.pid ][k] = v
    end
    --ply._ache = ache

    local tit_point = data._tit_point or {}
    for k, v in pairs(tit_point or {}) do
        gPendingSave.tit_point[ ply.pid ][k] = v
    end

    gPendingSave.title[ ply.pid ] = data._title
    
    --ply._tit_point = tit_point
    --ply.ache_point = data.ache_point

    ply:initEffect()

    ply:clear_task()   -- task
    gPendingSave.finished_task[ply.pid] = data._finish_task_list
    local cur_task_list = data._cur_task_list or {}
    for k, v in pairs(cur_task_list or {}) do
        local _id = ply.pid.."_"..v.task_id
        gPendingSave.task[_id] = v
    end

    local _first_blood = data._first_blood or{}
    gPendingSave.first_blood[ply.pid] = _first_blood

    for _, mail in pairs(mails or {}) do
        gPendingSave.mail[mail._id] = mail
    end


    --player_t._cache[pid] = pro
    gEtys[ eid ] = ply
    gPlys[ ply.pid ] = ply
    ply.size = 4
    ply.token = token
    gPendingSave.player[ ply.pid ].token = token
    etypipe.add(ply)

    local tr = ply:get_my_troop()
    if tr then
        for pid, arm in pairs(troop.arms or {}) do
            tr:add_arm(pid, arm)
        end
    end

    for k, v in pairs(timers) do
        timer._sns[v._id] = v
        timer.newTimer(v)
        timer.mark(v)
    end

    for _, mail in pairs(mails or {}) do
        gPendingSave.mail[mail._id] = mail
    end

    Rpc:callAgent( self.pid, "change_server_ack", pid, self.pid, pid ) 

    --if ply then
    --    pushHead(_G.GateSid, 0, 9)  -- set server id
    --    pushInt(ply.sockid)
    --    pushInt(self.pid)
    --    pushInt(ply.pid)
    --    pushOver()
    --    player_t.login( ply, ply.pid )
    --end
end

function change_server_ack(self, pid, map, ret)
    if ret ~= -1 then
        local ply = getPlayer(pid)
        if ply then
            -- pushHead(_G.GateSid, 0, 9)  -- set server id
            -- pushInt(ply.sockid)
            -- pushInt(self.pid)
            -- pushInt(ply.pid)
            -- pushOver()

            -- Rpc:callAgent(self.pid, "agent_login", pid, {})
            Rpc:cross_server_success(ply)
            ply:union_quit()
            gPendingSave.union_member[ ply.pid ] = 0
            clear_ply_info(pid)
            return
        end
    end
end


function agent_migrate( self, pid, x, y, data , timers, union_pro, troop, mails)
    --print("jump to server ", pid)
    -- 是否有空位    
    local from = self.pid
    --if c_map_test_pos( x, y, 4 ) ~= 0 then
    --    Rpc:callAgent( from, "agent_migrate_ack", pid, gMapID, -1 ) 
    --    return
    --end

    local eid = get_eid_ply()

    local pro = data._pro
    local tm_login = pro.tm_login
    pro.eid = eid
    pro.map = gMapID
    local ply = player_t.new( pro )
    --ply.x = x
    --ply.y = y
    ply.sockid = data.sockid 
    ply.tm_login = tm_login or gTime
    rawset( ply, "eid", eid )

    --ply._union = data._union
    gPendingSave.union_member[ply.pid] = ply._union

    local build = data._build or {}
    local bs = {}
    for k, v in pairs( build or {}) do
        b = v._pro
        bs[ b.idx ] = build_t.new( b )
    end
    ply._build = bs


    local hs = {}
    for k, v in pairs(data._hero or {}) do
        h = v._pro
        local hero = hero_t.new(h)
        hs[h.idx] = hero
        heromng.add_hero(hero)
    end
    ply._hero = hs

    local equip = data._equip or {}
    local es = {}
    for k, v in pairs(equip or {}) do
        local id = getId("equip")
        v._id = id
        gPendingSave.equip[ id ] = v
        es[id] = v
    end
    --ply._equip = es


    local item = data._item or {}
    ply._item = {}
    for k, _ in pairs(item) do
        ply:add_item_pend(k)
    end

    local count = data._count or {}
    for k, v in pairs(count or {}) do
        gPendingSave.count[ ply.pid ][k] = v
    end
    --ply._count = count

    local ache = data._ache or {}
    for k, v in pairs(ache or {}) do
        gPendingSave.ache[ ply.pid ][k] = v
    end
    --ply._ache = ache

    local tit_point = data._tit_point or {}
    for k, v in pairs(tit_point or {}) do
        gPendingSave.tit_point[ ply.pid ][k] = v
    end

    gPendingSave.title[ ply.pid ] = data._title
    
    --ply._tit_point = tit_point
    --ply.ache_point = data.ache_point

    --local arm = data.arm
    --local troop = troop_mng.create_troop(TroopAction.DefultFollow, ply, ply)
    --ply.my_troop_id = troop._id
    --for id, num in pairs( arm ) do
    --    troop:add_soldier( id, num )
    --end
    --
    ply:initEffect()

    ply:clear_task()   -- task
    gPendingSave.finished_task[ply.pid] = data._finish_task_list
    local cur_task_list = data._cur_task_list or {}
    for k, v in pairs(cur_task_list or {}) do
        local _id = ply.pid.."_"..v.task_id
        gPendingSave.task[_id] = v
    end

    local _first_blood = data._first_blood or{}
    gPendingSave.first_blood[ply.pid] = _first_blood


    --player_t._cache[pid] = pro
    gEtys[ eid ] = ply
    gPlys[ ply.pid ] = ply
    ply.size = 4
    ply.token = token
    gPendingSave.player[ ply.pid ].token = token
    etypipe.add(ply)

    local tr = ply:get_my_troop()
    if tr then
        for pid, arm in pairs(troop.arms or {}) do
            tr:add_arm(pid, arm)
        end
    end

    for k, v in pairs(timers) do
        timer._sns[v._id] = v
        timer.newTimer(v)
        timer.mark(v)
    end

    local union = unionmng.get_union(ply.uid)
    if not union then
        local u = union2_t.new(union_pro)
        union = u
        u.map_id = self.pid
        u.npc_citys = {}
        u.mc_act_ply = {} -- 参见本次mc活动玩家
        u.mc_ply_rank = {} -- 参见本次mc活动玩家
        u.mc_reward_pool = {}  -- 本次mc奖励
        u.mc_trs = {}          --mc出发的攻打npc部队
        u.mc_reward_pool = {}
        u.can_atk_citys = {}
        u.declare_wars = {}
        unionmng.add_union2(u)
    end
    local members = union._members or {}
    members[ply.pid] = ply
    union._members = members

    for _, mail in pairs(mails or {}) do
        gPendingSave.mail[mail._id] = mail
    end

    Rpc:callAgent( self.pid, "agent_migrate_ack", pid, self.pid, pid ) 

    --if ply then
    --    pushHead(_G.GateSid, 0, 9)  -- set server id
    --    pushInt(ply.sockid)
    --    pushInt(self.pid)
    --    pushInt(ply.pid)
    --    pushOver()
    --    player_t.login( ply, ply.pid )
    --end

end

function agent_migrate_back_ack(self, pid, map, ret)
    if ret ~= -1 then
        local ply = getPlayer(pid)
        if ply then
            pushHead(_G.GateSid, 0, 9)  -- set server id
            pushInt(ply.sockid)
            pushInt(self.pid)
            pushInt(ply.pid)
            pushOver()
            -- ply.cross_gs = self.pid

            --Rpc:callAgent(self.pid, "agent_login", pid, {})
            clear_ply_info(pid)
            return
        end
    else
        self:add_debug( "can not move" )
    end
end

function agent_migrate_back( self, pid, x, y, data , timers, union_pro, troop, todos, mails)
    --print("jump to server ", pid)
    -- 是否有空位    
    local from = self.pid
    --if c_map_test_pos( x, y, 4 ) ~= 0 then
    --    Rpc:callAgent( from, "agent_migrate_ack", pid, gMapID, -1 ) 
    --    return
    --end
    clear_ply_info(pid)

    local eid = get_eid_ply()

    local pro = data._pro
    local tm_login = pro.tm_login
    pro.eid = eid
    pro.map = gMapID
    local ply = player_t.new( pro )
    --ply.x = x
    --ply.y = y
    ply.sockid = data.sockid 
    ply.tm_login = tm_login or gTime
    rawset( ply, "eid", eid )

    ply._union = data._union
    gPendingSave.union_member[ply.pid] = ply._union

    local build = data._build or {}
    local bs = {}
    for k, v in pairs( build or {}) do
        b = v._pro
        bs[ b.idx ] = build_t.new( b )
    end
    ply._build = bs


    local hs = {}
    for k, v in pairs(data._hero or {}) do
        h = v._pro
        local hero = hero_t.new(h)
        hs[h.idx] = hero
        heromng.add_hero(hero)
    end
    ply._hero = hs

    local equip = data._equip or {}
    local es = {}
    for k, v in pairs(equip or {}) do
        local id = getId("equip")
        v._id = id
        gPendingSave.equip[ id ] = v
        es[id] = v
    end
    ply._equip = es


    local item = data._item or {}
    ply._item = item
    for k, _ in pairs(item) do
        ply:add_item_pend(k)
    end

    local count = data._count or {}
    for k, v in pairs(count or {}) do
        gPendingSave.count[ ply.pid ][k] = v
    end
    ply._count = count

    local ache = data._ache or {}
    for k, v in pairs(ache or {}) do
        gPendingSave.ache[ ply.pid ][k] = v
    end
    ply._ache = ache

    local tit_point = data._tit_point or {}
    for k, v in pairs(tit_point or {}) do
        gPendingSave.tit_point[ self.pid ][k] = v
    end
    ply._tit_point = tit_point
    ply.ache_point = data.ache_point

    --local arm = data.arm
    --local troop = troop_mng.create_troop(TroopAction.DefultFollow, ply, ply)
    --ply.my_troop_id = troop._id
    --for id, num in pairs( arm ) do
    --    troop:add_soldier( id, num )
    --end
    ply:initEffect()

    ply:clear_task()
    gPendingSave.finished_task[self.pid] = data._finish_task_list
    local cur_task_list = data._cur_task_list or {}
    for k, v in pairs(cur_task_list or {}) do
        local _id = ply.pid.."_"..v.task_id
        gPendingSave.task[_id] = v
    end

    player_t._cache[pid] = pro
    gEtys[ eid ] = ply
    ply.size = 4
    etypipe.add(ply)
    gPendingSave.player[ ply.pid ].token = token
    etypipe.add(ply)

    local tr_old = ply:get_my_troop()
    troop_mng.delete_troop(tr_old)
    ply.my_troop_id = nil

    local tr= ply:get_my_troop()
    if tr then
        for k, v in pairs(troop.arms or {}) do
            tr:add_arm(k, v)
        end
    end

    for k, v in pairs(timers or {}) do
        timer._sns[v._id] = v
        timer.newTimer(v)
        timer.mark(v)
    end

    for _, v in pairs(todos or {}) do
        gPendingInsert.todo[v._id] = v
    end

    for _, mail in pairs(mails or {}) do
        gPendingSave.mail[mail._id] = mail
    end

    --local union = unionmng.get_union(ply.uid)
    --if not union then
    --    local u = union2_t.new(union_pro)
    --    union = u
    --    u.map_id = self.pid
    --    unionmng.add_union2(u)
    --end
    --local members = union._members or {}
    --members[ply.pid] = ply
    --union._members = members
    ply.map = gMapID

    Rpc:callAgent( self.pid, "agent_migrate_back_ack", pid, self.pid, pid ) 
end



---cross act

function cross_act_ntf(self, ntf_id, ...)
    local arg = { ... } or {}
    local prop = resmng.get_conf("prop_cross_act_notify", ntf_id)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify, arg[1] or {})
        end
        if prop.Chat1 then
            player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", prop.Chat1, arg[1])
        end
        if prop.SendMail then
            player_t.send_system_to_all(prop.SendMail, arg[3] or {}, arg[1] or {}, arg[2])
        end
    end
end

function post_npc_change(self, propid, map_id, tag)
    cross_mng_c.npc_change(self.pid, propid, map_id, tag)
end

function cross_act_st_cast(self, pack)
    cross_act.rec_cross_act_st(pack)
end

function cross_act_st_req(self, param)
    cross_mng_c.cross_act_st_req(self.pid)
end

function upload_gs_info(self, gs_info)
    cross_mng_c.upload_gs_info(gs_info)
end

--function upload_union_info(self, union)
--    cross_mng_c.upload_union_info(union)
--end

function cross_gm(self, pack)
    if pack[2] == "1" then
        cross_mng_c.cross_act_prepare()
    end
    if pack[2] == "2" then
        cross_mng_c.cross_act_fight()
    end
    if pack[2] == "3" then
        cross_mng_c.cross_act_end()
    end
    if pack[2] == "4" then
        cross_refugee_c.cross_refugee_start()
    end
    if pack[2] == "5" then
        cross_refugee_c.cross_refugee_end()
    end
    if pack[2] == "debug" then
        cross_mng_c.debug_tag = cross_mng_c.debug_tag * -1
    end
end

function refugee_end(self)
    refugee.clear_all_refugee()
end

function refugee_change(self, pid, mode, info)
    local ply = getPlayer(pid)
    if ply then
        local refugee_info = ply.refugee_info or {}
        if mode == 0 then
            refugee_info[info.eid] = nil
        else
            refugee_info[info.eid] = info
        end
    end
    ply.refugee_info = refugee_info
end

function cross_npc_info_req(self, pid)
    local gs_id = self.pid
    local gs = gs_pool[gs_id]
    local pack = {}
    if gs then
        local info = {}
        info.left_npc = gs.left_npc
        info.occu_npc = gs.occu_npc
        pack.pid = pid
        pack.info = info

        Rpc:callAgent(gs_id, "cross_npc_info_ack", pack)
    end
end

function cross_npc_info_ack(self, pack)
    local ply = getPlayer(pack.pid)
    if ply then
        ply:cross_npc_info_ack(pack.info)
    end
end

function upload_act_score(self, action, val, pack)
    cross_rank_c.update_score(action, val, unpack(pack))
end

function send_cross_award(self, rank_mode, reward_mode, id, award, param)
    do_send_award[rank_mode](reward_mode, id, award, param)
end

do_send_award = {}

do_send_award[RANK_MODE.PLY] = function(mail_num, id, award, param)
    local ply = getPlayer(id)
    if ply then
        ply:send_system_notice(mail_num, param or {}, {},award)
    end
end

do_send_award[RANK_MODE.UNION] = function(mail_num, id, award, param)
    local union = unionmng.get_union(id)
    if union then
        for _, ply in pairs(union._members or {}) do
            ply:send_system_notice(mail_num, param or {}, {}, award)
        end
    end
end

function gm_cmd(self, proc_id, gm_type, param)
    local ret = {code = 0, msg = "param error"}
    if do_gm_cmd[gm_type] then
        ret = do_gm_cmd[gm_type](param)
        to_tool(0, {type = "gm_ack", gm_type = gm_type, proc_id = proc_id, result = ret})
    else
        to_tool(0, {type = "gm_ack", gm_type = gm_type, proc_id = proc_id, result = {code = 0, msg = "no this cmd"}})
    end
end

do_gm_cmd = {}

do_gm_cmd["pay"] = function(param)
    local ext = Json.decode(param.ext_info or "")
    local extend = Json.decode(ext.extend or "")
    local ply_id 
    if extend then
        ply_id = tonumber(extend.pid)
    end
    local order_id = param.order_id
    local product_id = tonumber(param.pid)
    local pay_amount = tonumber(param.quantity)

    INFO( "[pay], pid=%s, order_id=%s, product_id=%s, pay_amount=%s", ply_id or "unknown", order_id or "unknown", product_id or "unknown", pay_amount or "unknown" )

    if not ply_id or not order_id or not product_id or not pay_amount then
        LOG("GM CMD pay param error ~p", param)
        return {code = 0, msg = "param error"}
    end

    local ply = getPlayer(ply_id)
    if not ply then
        LOG("GM CMD PAY did not find ply")
        INFO( "[pay], error, pid=%d, order_id=%s, product_id=%s, pay_amount=%s, no player", ply_id, order_id, product_id, pay_amount )
        return {code = 0, msg = "no this ply"}
    end

    if param.order_id then
        local db = dbmng:getOne()
        local info =db.order:findOne({_id = param.order_id})
        if not info then

            info = { _id = param.order_id,
            info = param,
        }
            gPendingInsert.order[ info._id ] = info 

            local result = {}

            if ply.emap == ply.map then
                result = ply:on_pay( product_id, true )  -- 本服充值
            else
                result = remote_func(ply.map, "agent_on_pay", {"player", ply.pid, product_id, true, gMapID})  -- 夸服pay
            end

            if result.code == 1 then 
                local prop = resmng.prop_buy[product_id]
                if prop then
                    local rmb =  prop.NewPrice or 0
                    ply.rmb = (ply.rmb or 0) + rmb 
                    ply:pre_tlog("PayFlow",rmb,((prop.Gold or 0) + (prop.ExtraGold or 0)),param.order_id ,"null")
                else
                    ply:pre_tlog("PayFlow",product_id,0,param.order_id ,"null")
                end
                INFO( "[pay], ok, pid=%s, order_id=%s, product_id=%s, pay_amount=%s", ply_id or "unknown", order_id or "unknown", product_id or "unknown", pay_amount or "unknown" )
            end
            return result

        else
            INFO( "[pay], error, pid=%d, order_id=%s, product_id=%s, pay_amount=%s, duplicate", ply_id, order_id, product_id, pay_amount )
            return {code = 1, msg = "success"}
            --return {code = 0, msg = "already pay"}
        end
    end

    return {code = 0, msg = "no order info in req"}
end

function gm_add_ply_item(ply, awards, reason)
    ply:add_bonus( "mutex_award", awards, reason)
end

function gm_add_union_item(ply, awards)
    local union = unionmng.get_union(ply.uid)
    if union then
        for _, mem in pairs(union._members or {}) do
            union_item.add(mem, awards, UNION_ITEM.CITY, 0)
        end
    end
end

local cond_lists = {
    "bylevel",
    "regtime",
}

check_condition = {}

check_condition["bylevel"] = function(ply, cond)
    local lv = ply:get_castle_lv()
    if type(cond[1]) ~= "number" or type(cond[2]) ~= "number" then
        return {code = 0, msg = "param error"}
    end
    if cond[1] == 0 and cond[2] == 0 then
        return true
    end
    if lv >= cond[1] and lv <= cond[2] then
        return true
    end
    return false
end

--check_condition["byregtime"] = function(ply, cond)
--    local tm = ply.tm_create
--    local st_tm = 1
--    local end_tm = 1
--    if type(cond[1]) ~= "string" or type(cond[2]) ~= "string" then
--        return {code = 0, msg = "param error"}
--    end
--    if cond[1] == "0000-00-00" and cond[2] == "0000-00-00" then
--        return true
--    end
--    if lv >= st_tm and lv < end_tm then
--        return true
--    end
--    return false
--end

function find_list_by_conds(param)
    local list = {}
    local all = true --是否使用全服邮件
    for _, ply in pairs(gPlys or {}) do
        local hit = true
        for key, cond in pairs(param or {}) do
            if check_condition[key] then
                local ret = check_condition[key](ply, cond)
                if type(ret) == "table" then
                    return ret
                else
                    hit = ret
                    if hit == false then
                        all = false
                        break
                    end
                end
            end
        end
        if hit == true then
            table.insert(list, ply.pid)
        end
    end
    return list, all
end

do_gm_cmd["senditem"] = function(param)
    local ply_id = ""
    if param.player_id ~= "all" then
        ply_id = tonumber(param.player_id)
    else
        ply_id = "all"
    end
    local title = param.title
    local content = param.content
    local mail_id = 10031

    if not ply_id or not title or not content then
        LOG("GM CMD senditem param error ~p", param)
        return {code = 0, msg = "param error"}
    end

    local item = {}
    for k, v in pairs(param.item or {}) do
        local award = {v.type, tonumber(v.id), tonumber(v.num), 10000}
        table.insert(item, award)
    end

    if param.player_id == "all" then
        local list, all_ply = find_list_by_conds(param)
        if list["code"] then -- 查询参数错误
            return list
        end
        if all_ply then
            player_t.send_system_to_all(mail_id, {title}, {content}, item)
            return {code = 1, msg = "success to all ply"}
        else
            for _, pid in pairs(list or {}) do
                local p = getPlayer(pid)
                if p then
                    p:send_system_notice(mail_id, {title}, {content}, item)
                end
            end
            return {code = 1, msg = list}
        end
    else
        if ply_id < 10000 then
            LOG("GM CMD PAY did not find ply")
            return {code = 0, msg = "no this ply"}
        end
        local ply = getPlayer(ply_id)
        if not ply then
            LOG("GM CMD PAY did not find ply")
            return {code = 0, msg = "no this ply"}
        else
            ply:send_system_notice(mail_id, {title}, {content}, item)
            return {code = 1, msg = "success"}
        end
    end

    --if param.order_id then
    --    local db = dbmng:getOne()
    --    local info =db.order:findOne({_id = param.order_id})
    --    if not info then
    --        info = {_id = param.order_id,}
    --        db.order:insert(info, {["$set"] = param}, true)
    --        LOG("GM CMD PAY pid = %s order_id %d", param.order_id, ply_id)
    --        ply:gm_add_gold(10000)
    --        return {code = 1, msg = "success"}
    --    else
    --        return {code = 0, msg = "already pay"}
    --    end
    --end
    --return {code = 0, msg = "no order info in req"}
end

do_gm_cmd["sendgm"] = function(content)
    return gmcmd.do_cmd(content)
    --return {code = 1, msg = "success"}
end

do_gm_cmd["sendjoinrun"] = function(param)
    gPendingSave.status["joinrun"].cmd = param
    return {code = 1, msg = "success"}
end



