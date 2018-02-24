module( "agent_t", package.seeall )

function agent_test( self, info, info1)
    pause()
end

function agent_test_struct( self, id, mems, name )
    pause()
    print("ok")
end

function agent_mov_eye( self, pid, x, y )
    c_mov_eye(pid, x, y)
end

function agent_add_eye( self, pid, x, y )
    c_add_eye(pid, x, y)
end

function agent_rem_eye( self, pid )
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
    elseif arg[1] == "union_tech" then
        local uid = arg[2]
        local union = unionmng.get_union(uid)
        if union then
            table.remove(arg, 1)
            table.remove(arg, 1)
            local val = union_tech_t[func](union, self.pid, id, unpack(arg))
            if id ~= 0 then
                Rpc:callAgent(map_id, "agent_syn_call_ack", id, val or {})
                return
            end
        end
    elseif arg[1] == "union_buildlv" then
        local uid = arg[2]
        local union = unionmng.get_union(uid)
        if union then
            table.remove(arg, 1)
            table.remove(arg, 1)
            local val = union_buildlv[func](union, self.pid, id, unpack(arg))
            if id ~= 0 then
                Rpc:callAgent(map_id, "agent_syn_call_ack", id, val or {})
                return
            end
        end
    elseif arg[1] == "union_mission" then
        local uid = arg[2]
        local union = unionmng.get_union(uid)
        if union then
            table.remove(arg, 1)
            table.remove(arg, 1)
            local val = union_mission[func](union, self.pid, id, unpack(arg))
            if id ~= 0 then
                Rpc:callAgent(map_id, "agent_syn_call_ack", id, val or {})
                return
            end
        end
    elseif arg[1] == "union_item" then
        local pid = arg[2]
        local ply = getPlayer(pid)
        if ply then
            table.remove(arg, 1)
            table.remove(arg, 1)
            local val = union_item[func](ply, unpack(arg))
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
    elseif arg[1] == "playerex" then
        local pid = arg[2]
        local ply = getPlayer(pid)
        if ply then
            table.remove(arg, 1)
            table.remove(arg, 1)
            if id ~= 0 then
                local val = {player_t[func](ply, unpack(arg))}
                Rpc:callAgent(map_id, "agent_syn_call_ack", id, val)
                return
            else
                player_t[func](ply, unpack(arg))
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
    coroutine.resume(co, E_OK, ret)
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
            if info.crossing then
                ply:on_cross_migrate()
            else
                ply:on_cross_login()
            end
        end
    end
end

function rebuild_player(data, emap)
    local eid = get_eid_ply()
    local pro = data._pro

    pro.eid = eid
    pro.map = gMapID
    pro.emap = emap or pro.emap

    local player = player_t.new(data._pro)
    player.sockid = data.sockid
    player.tm_login = pro.tm_login or gTime
    player.tm_logout = gTime
    player.my_troop_id = 0
    rawset(player, "eid", eid)

    local pid = player.pid
    -- build
    local builds = {}
    for k, v in pairs(data._build or {}) do
        builds[v._pro.idx] = build_t.new(v._pro)
    end
    player._build = builds
    -- hero
    local heroes = {}
    for k, v in pairs(data._hero or {}) do
        local hero = hero_t.new(v._pro)
        heroes[v._pro.idx] = hero
        heromng.add_hero(hero)
    end
    player._hero = heroes
    -- equip
    local equips = {}
    for k, v in pairs(data._equip or {}) do
        equips[v._id] = v
        gPendingInsert.equip[v._id] = v
    end
    player._equip = equips
    -- item
    if data._item then
        player._item = data._item
        gPendingInsert.item[pid] = data._item
    end
    -- ache
    if data._ache then
        player._ache = data._ache
        gPendingInsert.ache[pid] = data._ache
    end
    -- count
    if data._count then
        player._count = data._count
        gPendingInsert.count[pid] = data._count
    end
    -- first blood
    if data._first_blood then
        player._first_blood = data._first_blood
        gPendingInsert.first_blood[pid] = data._first_blood
    end
    -- client param
    if data._client_param then
        player._client_param = data._client_param
        gPendingInsert.client_parm[pid] = data._client_param
    end

    player:initEffect()
    -- task
    player:load_task_from_data(data._cur_task_list, data._finish_task_list)

    rawset( player, "_access", gTime )
    return player
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
        gPendingDelete.equip[v._id] = 0
    end
    ply._equip = nil

    local item = ply.item or {}
    gPendingDelete.item[ ply.pid ] = 0
    ply.item = nil

    local count = ply._count or {}
    gPendingDelete.count[ ply.pid ] = 0
    ply._count = nil

    --gPendingDelete.title[ ply.pid ] = 0
    --gPendingDelete.tit_point[ ply.pid ] = 0

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

    local db = dbmng:getOne()
    if db then
        db.mail:delete({to = pid}, false)
    end

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

            local info = {}
            info.token = ply.token
            info.sockid = ply.sockid
            info.ip = ply.ip
            info.crossing = true
            Rpc:callAgent(self.pid, "agent_login", pid, info)
            if ply.emap == gMapID then
                ply.map = self.pid
                rem_ety(ply.eid)
                ply.eid = 0
                return
            else
                local union = unionmng.get_union(ply.uid)
                if union then
                    union._members[ply.pid] = nil
                    gPendingDelete.union_member[ply.pid] = 0
                end
                clear_ply_info(pid)
                return
            end
        end
    else
        self:add_debug( "can not move" )
    end
end

function change_server( self, pid, x, y, data)
    -- 是否有空位    
    local from = self.pid
    --if c_map_test_pos( x, y, 4 ) ~= 0 then
    --    Rpc:callAgent( from, "change_server_ack", pid, gMapID, -1 ) 
    --    return
    --end

    local ply = player_t.player_data_push(data)
    ply.x = x
    ply.y = y
    ply.uid = nil
    ply.mail_sys = gSysMailSn

    gEtys[ ply.eid ] = ply
    gPlys[ ply.pid ] = ply
    ply.size = 4
    etypipe.add(ply)

    Rpc:callAgent( self.pid, "change_server_ack", pid, self.pid, pid ) 
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


function agent_migrate( self, pid, x, y, data, union_pro)
    --print("jump to server ", pid)
    -- 是否有空位    
    local from = self.pid
    --if c_map_test_pos( x, y, 4 ) ~= 0 then
    --    Rpc:callAgent( from, "agent_migrate_ack", pid, gMapID, -1 ) 
    --    return
    --end

    local ply = player_t.player_data_push(data)
    ply.mail_sys = gSysMailSn

    ply._union = data.union_member
    gPendingSave.union_member[ply.pid] = ply._union

    gEtys[ ply.eid ] = ply
    gPlys[ ply.pid ] = ply
    ply.size = 4
    ply.x = x
    ply.y = y
    etypipe.add(ply)

    king_city.add_officer_buff(ply)

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

    Rpc:callAgent( self.pid, "agent_migrate_ack", pid, self.pid, pid ) 
end

function agent_migrate_back_ack(self, pid, map, ret)
    if ret ~= -1 then
        local ply = getPlayer(pid)
        if ply then
            if ply:is_online() then
                pushHead(_G.GateSid, 0, 9)  -- set server id
                pushInt(ply.sockid)
                pushInt(self.pid)
                pushInt(ply.pid)
                pushOver()

                local info = {}
                info.token = ply.token
                info.sockid = ply.sockid
                info.ip = ply.ip
                Rpc:callAgent(self.pid, "agent_login", pid, info)
            end

            local union = unionmng.get_union(ply.uid)
            if union then
                union._members[ply.pid] = nil
                gPendingDelete.union_member[ply.pid] = 0
            end

            ply:del_mark("cross_migrate_back")
            clear_ply_info(pid)
            return
        end
    else
        self:add_debug( "can not move" )
    end
end

function agent_migrate_back( self, pid, x, y, data, union_pro)
    --print("jump to server ", pid)
    -- 是否有空位    
    local from = self.pid
    --if c_map_test_pos( x, y, 4 ) ~= 0 then
    --    Rpc:callAgent( from, "agent_migrate_ack", pid, gMapID, -1 ) 
    --    return
    --end

    if -1 == x or -1 == y then
        local lv_castle = math.floor(data.player.propid % 1000)
        if lv_castle < 6 then
            x, y = player_t.get_pos_by_range_lv( 1, 1 )
        elseif lv_castle < 10 then
            x, y = player_t.get_pos_by_range_lv( 1, 2 )
        elseif lv_castle < 12 then
            x, y = player_t.get_pos_by_range_lv( 1, 3 )
        elseif lv_castle < 15 then
            x, y = player_t.get_pos_by_range_lv( 1, 4 )
        else
            x, y = player_t.get_pos_by_range_lv( 1, 5 )
        end
        if not x then
            x, y = data.player.x, data.player.y
        end
    end

    local old_player = getPlayer(pid)
    player_t.player_data_reset(pid)

    local ply = player_t.player_data_push(data)
    ply.mail_sys = old_player and old_player.mail_sys or gSysMailSn

    ply._union = data.union_member
    gPendingSave.union_member[ply.pid] = ply._union

    gEtys[ ply.eid ] = ply
    gPlys[ ply.pid ] = ply
    ply.size = 4
    ply.x = x
    ply.y = y
    etypipe.add(ply)

    king_city.add_officer_buff(ply)

    local union = unionmng.get_union(ply.uid)
    if nil ~= union then
        if nil ~= union._members[ply.pid] then
            union._members[ply.pid] = ply
        end
    end
    union_item.load(ply.pid)

    Rpc:callAgent( self.pid, "agent_migrate_back_ack", pid, self.pid, pid ) 
end



---cross act
function cross_ask_game_info(self)
    if self.pid ~= gCenterID then
        return
    end
    crontab.upload_gs_info()
    cross_act.upload_royal_city_info()
end

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

function post_npc_change(self, royalty_id, map_id, tag)
    cross_mng_c.npc_change(self.pid, royalty_id, map_id, tag)
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

function cross_group_info(self, group_info)
    cross_act.rec_group_info(group_info.servers)
end

--function upload_union_info(self, union)
--    cross_mng_c.upload_union_info(union)
--end

function cross_gm(self, pack)
    if pack[2] == "0" then
        cross_mng_c.load_next_war()
    end
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
        cross_mng_c.cross_act_fight()
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

function cross_royal_city_info(self, info)
    cross_mng_c.update_royal_city_info(self.pid, info)
end

function cross_npc_info_req(self, gid, pid)
    local gs = cross_mng_c.gs_pool[gid]
    local pack = {}
    if gs then
        local info = {}
        info.left_npc = gs.left_npc
        info.occu_npc = gs.occu_npc
        info.cities = gs.royal_cities
        pack.pid = pid
        pack.info = info

        Rpc:callAgent(self.pid, "cross_npc_info_ack", gid, pack)
    end
end

function cross_npc_info_ack(self, gid, pack)
    local ply = getPlayer(pack.pid)
    if ply then
        Rpc:cross_npc_info_ack(ply, gid, pack.info)
    end
end

function cross_royalty_servers_req(self, pid)
    local gs = cross_mng_c.get_gs_info(self.pid)
    if not gs or 0 == gs.group then
        return
    end
    Rpc:callAgent(self.pid, "cross_royalty_servers_ack", pid, cross_mng_c.pack_royalty_servers(gs.group))
end

function cross_royalty_servers_ack(self, pid, servers)
    local player = getPlayer(pid)
    if player then
        Rpc:cross_royalty_servers_ack(player, servers)
    end
end

function cross_rank_info_req(self, pid, uid, gs_id, mode, version)
    local rank_version, rank_list = cross_rank_c.get_rank_info(gs_id, mode)
    local info = {}
    info.mode = mode
    info.version = rank_version
    info.my_rank = 0
    if mode == CUSTOM_RANK_MODE.PLY then
        info.my_rank = cross_rank_c.get_rank(gs_id, mode, pid)
    elseif mode == CUSTOM_RANK_MODE.UNION then
        if 0 ~= uid then
            info.my_rank = cross_rank_c.get_rank(gs_id, mode, uid)
        end
    elseif mode == CUSTOM_RANK_MODE.GS then
        info.my_rank = cross_rank_c.get_rank(gs_id, mode, gs_id)
    end
    info.rank_list = rank_list
    info.extra = {
        countdown = cross_mng_c.get_end_time(),
    }

    Rpc:callAgent(self.pid, "cross_rank_info_ack", pid, info)
end

function cross_rank_info_ack(self, pid, info)
    local player = getPlayer(pid)
    if player then
        Rpc:cross_rank_info(player, info.mode, info.version, info.my_rank, info.rank_list, info.extra)
    end
end

function cross_royalty_reward(self, items)
    local award = {}
    for k, v in pairs(items) do
        table.insert(award, {"item", v[1], v[2], 10000})
    end
    player_t.send_system_to_all(ROYAL_REWARD_MAIL, {}, {}, award)
end

function upload_act_score(self, action, gs_id, val, pack)
    cross_rank_c.update_score(action, gs_id, val, unpack(pack))
end

function upload_refugee_score(self, gs_id, pid, score)
    cross_rank_c.add_refugee_score(gs_id, pid, score)
end

function cross_refugee_rank_info_req(self, pid, gs_id)
    local info = {}
    info.my_rank = cross_rank_c.get_refugee_rank(gs_id, pid)
    info.my_score = cross_rank_c.get_refugee_rank_score(gs_id, pid)
    info.end_time = cross_mng_c.get_end_time()

    Rpc:callAgent(self.pid, "cross_refugee_rank_info_ack", pid, info)
end

function cross_refugee_rank_info_ack(self, pid, info)
    local player = getPlayer(pid)
    if player then
        Rpc:cross_refugee_rank_info(player, info.my_rank, info.my_score, info.end_time)
    end
end

function cross_refugee_rank_list_req(self, pid, gs_id)
    local rank_version, rank_list = cross_rank_c.get_refugee_rank_info(gs_id)
    local info = {}
    info.version = rank_version
    info.rank_list = rank_list
    info.my_rank = cross_rank_c.get_refugee_rank(gs_id, pid)
    info.extra = {
        countdown = cross_mng_c.get_end_time(),
    }
    Rpc:callAgent(self.pid, "cross_refugee_rank_list_ack", pid, info)
end

function cross_refugee_rank_list_ack(self, pid, info)
    local player = getPlayer(pid)
    if player then
        Rpc:cross_refugee_rank_list(player, info.version, info.my_rank, info.rank_list, info.extra)
    end
end

function cross_release_hero(self, capture_pid, pid, hero_id, hero_idx)
    local player = getPlayer(pid)
    if nil == player then
        Rpc:callAgent(self.pid, "cross_release_hero_pid", -1, capture_pid, hero_id)
        return
    end
    local state = player:get_cross_state()
    local ret = 0
    if PLAYER_CROSS_STATE.IN_LOCAL_SERVER == state then
        player:do_cross_release(hero_id, hero_idx)
    elseif PLAYER_CROSS_STATE.IN_OTHER_SERVER == state then
        player:remote_release_hero(hero_id, hero_idx)
    else
        ret = -2
    end
    Rpc:callAgent(self.pid, "cross_release_hero_ack", ret, capture_pid, hero_id)
end

function cross_release_hero_ack(self, ret, pid, hero_id)
    if 0 == ret then
        heromng.destroy_hero(hero_id, true)
    end
end

function cross_kill_hero(self, pid, hero_idx)
    local player = getPlayer(pid)
    if nil == player then
        WARN("Not found player %d when hero is killed in cross server", pid)
        return
    end
    local state = player:get_cross_state()
    if PLAYER_CROSS_STATE.IN_LOCAL_SERVER == state then
        player:do_cross_kill_hero(hero_idx)
    elseif PLAYER_CROSS_STATE.IN_OTHER_SERVER == state then
        player:remote_kill_hero(hero_idx)
    end
end

function notify_cross_award(self, pids)
    timer.new("batch_claim_cross_award", 2, pids)
end

function claim_player_cross_award(self, pid)
    local awards = player_rank_award.claim_all_awards(pid)
    if not awards then
        return
    end
    Rpc:callAgent(self.pid, "claim_player_cross_award_ack", pid, awards)
end

function claim_player_cross_award_ack(self, pid, awards)
    local player = getPlayer(pid)
    if not player then
        return
    end
    for k, v in pairs(awards) do
        player:send_system_notice(v[2], {}, v[4], v[3])
        INFO("[Cross|RankAward] Player %d claimed award %d", pid, v[1])
    end
end

function send_cross_award(self, rank_mode, reward_mode, id, award, param)
    do_send_award[rank_mode](reward_mode, id, award, param)
end

do_send_award = {}

do_send_award[CUSTOM_RANK_MODE.PLY] = function(mail_num, id, award, param)
    local ply = getPlayer(id)
    if ply then
        ply:send_system_notice(mail_num, {}, param or {}, award)
    end
end

do_send_award[CUSTOM_RANK_MODE.UNION] = function(mail_num, id, award, param)
    local union = unionmng.get_union(id)
    if union then
        for _, ply in pairs(union._members or {}) do
            ply:send_system_notice(mail_num, {}, param or {}, award)
        end
    end
end

do_send_award[CUSTOM_RANK_MODE.GS] = function(mail_num, id, award, param)
    player_t.send_system_to_all(mail_num, {}, param or {}, award)
end

function send_end_tw_award(self, uid, award)
    local union = unionmng.get_union(uid)
    if union then
        local members = union:get_members()
        for pid, player in pairs(members or {}) do
            if npc_city.check_ply_can_award(player) then
                player:send_system_notice(10012, {}, {}, award)
            end
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
    --local extend = Json.decode(ext.extend or "")
    local ply_id 
    if ext then
        ply_id = tonumber(ext.player_id or "0")
    end
    local order_id = param.order_id
    local product_id = tonumber(param.pid)
    local pay_amount = tonumber(param.quantity)
    local cpid = param.cpid

    WARN( "[pay], pid,%s, order_id,%s, product_id,%s, pay_amount,%s", ply_id or "unknown", order_id or "unknown", product_id or "unknown", pay_amount or "unknown" )

    if not ply_id or not order_id or not product_id or not pay_amount then
        WARN("GM CMD pay param error ~p", param)
        return {code = 0, msg = "param error"}
    end

    local buy_prop = resmng.prop_buy[product_id]
    if not buy_prop then
        WARN("GM CMD pay can not find product prop by product_id=%d ~p", product_id)
        return {code = 0, msg = "can not find product prop"}
    end

    if buy_prop.AppleBuyID ~= cpid then
        WARN("GM CMD pay product_id=%d cpid=%s can not match cpid=%s in prop ~p", product_id, buy_prop.AppleBuyID,cpid)
        return {code = 0, msg = "product_id did not match cpid"}
    end

    local ply = getPlayer(ply_id)
    if not ply then
        WARN("GM CMD PAY did not find ply")
        WARN( "[pay], error, pid=%d, order_id=%s, product_id=%s, pay_amount=%s, no player", ply_id, order_id, product_id, pay_amount )
        return {code = 0, msg = "no this ply"}
    end

    if param.order_id then
        local db = dbmng:getOne()
        local info =db.order:findOne({_id = param.order_id}) or {}
        if info.status == nil then
            info = { _id = param.order_id, info = param, }
            gPendingInsert.order[ info._id ] = info 

            local result = {}
            if ply.emap == ply.map then
                result = ply:on_pay( product_id, true )  -- 本服充值
            else
                local call_ret
                call_ret, result = remote_func(ply.map, "agent_on_pay", {"player", ply.pid, product_id, true, gMapID})  -- 夸服pay
                if E_OK ~= call_ret then
                    return {code = 0, msg = "failed to call remote_func"}
                end
            end

            if result.code == 1 then 
                info.status = "finish"
                gPendingSave.order[ info._id ] = info 

                local prop = resmng.prop_buy[product_id]
                if prop then
                    local rmb =  prop.NewPrice_US or 0
                    ply.rmb = (ply.rmb or 0) + rmb 
                    ply:pre_tlog("PayFlow",rmb,((prop.Gold or 0) + (prop.ExtraGold or 0)),product_id,param.order_id ,"null",tms2str(gTime))
                else
                    ply:pre_tlog("PayFlow",product_id,0,0,param.order_id ,"null",tms2str(gTime))
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
    local title = param.title or "欢迎来到铁血帝国"
    local content = param.content or "这是文明的荣耀，这是战争的喷张"
    local mail_id = tonumber(param.mail_id) or 10031

    if mail_id == 10032 then   --- 10001 默认  10031 %s 10032%z
        title = tonumber(title)
        content = tonumber(content)
    end

    --if not ply_id or not title or not content then
    if not ply_id then
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

-- periodic_activity
function periodic_activity_get_activity_data(self)
    periodic_activity_manager.sync_activity_data(self.pid, PERIODIC_ACTIVITY.DAILY)
    periodic_activity_manager.sync_activity_data(self.pid, PERIODIC_ACTIVITY.BIHOURLY)
end

function periodic_activity_sync_data(self, mode, group_id, sn, start_time, end_time)
    if self.pid ~= gCenterID then
        return
    end
    daily_activity.update_data(mode, group_id, sn, start_time, end_time)
end

function periodic_activity_reset_player_data(self, mode)
    if self.pid ~= gCenterID then
        return
    end
    if mode == PERIODIC_ACTIVITY.DAILY then
        for _, ply in pairs(gPlys or {}) do
            ply.daily_activity_info = {
                activity_num = 0,
                rank_lv = 1,
                score = {},
                award_tag = 0,
            }
        end
    elseif mode == PERIODIC_ACTIVITY.BIHOURLY then
        for _, ply in pairs(gPlys or {}) do
            ply.bihourly_activity_info = {
                activity_num = 0,
                rank_lv = 1,
                score = {},
                award_tag = 0,
            }
        end
    end
end

function periodic_activity_upload_score(self, mode, sn, gid, pid, rank_lv, score, time)
    periodic_activity_manager.upload_score(mode, gid, pid, rank_lv, score, time)
    Rpc:callAgent(self.pid, "periodic_activity_upload_score_ack", mode, sn, pid)
end

function periodic_activity_upload_score_ack(self, mode, sn, pid)
    local player = getPlayer(pid)
    if player then
        player:clear_periodic_upload_watcher(mode, sn)
    end
end

function periodic_activity_get_my_rank(self, mode, gid, pid, rank_lv)
    local rank_pos, ahead_score = periodic_activity_manager.get_my_rank(mode, gid, pid, rank_lv)
    Rpc:callAgent(self.pid, "periodic_activity_get_my_rank_ack", mode, pid, rank_pos, ahead_score)
end

function periodic_activity_get_my_rank_ack(self, mode, pid, rank_pos, ahead_score)
    local player = getPlayer(pid)
    if player then
        Rpc:get_my_periodic_rank(player, mode, rank_pos, ahead_score)
    end
end

function periodic_activity_gm_refresh_activity(self, mode, index)
    periodic_activity_manager.refresh_activity(mode, index)
end

function periodic_activity_reinit_data(self, info)
    periodic_activity_manager.clear_player_rank(self.pid, info)
end

