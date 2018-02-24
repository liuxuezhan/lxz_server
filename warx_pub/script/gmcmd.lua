module( "gmcmd", package.seeall )


function do_cmd(cmd)
    INFO("[GM] gm cmd %s " , Json.encode(cmd or {}))
    local gm_type = cmd.cmd

    local cmd_item = gmcmd_table[ gm_type ]
    if cmd_item == nil or not cmd_item then
        return {code = 0, msg = "no this cmd"}
    end

    return cmd_item[2](cmd.pids, unpack(cmd.param or {}) )

end

function showbuf(pids)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        return {code = 1, msg = ply.bufs}
    end
    return {code = 0, msg = "no ply"}
end

function opt_ply(pids1, uid, treat_type, actor_id, actor_name )
    local pids =  {}
    if actor_id then
        table.insert(pids, tonumber(actor_id))
    else
        local db = dbmng:getOne()
        local info = db.player:find({account=uid})
        while info:hasNext() do
            local data = info:next()
            table.insert(pids, data.pid)
        end
    end

    if type(treat_type) == "string" then
        treat_type = tonumber(treat_type)
    end
    local ret = {}
    for _, pid in pairs(pids or {}) do
        if treat_type == 1 then
           ret =  nospeak({pid}, 7 * 24 * 3600)
        elseif treat_type == 2 then
            ret = speakable({pid})
        elseif treat_type == 3 then
            ret = loginout({pid})
        elseif treat_type == 4 then
            ret = nologin({pid}, 7 * 24 * 3600)
        elseif treat_type == 5 then
            ret = loginable({pid})
        end
    end
    return ret
end

function nospeak(pids, time)
    if type(pids[1]) == string then
        pids[1] = tonumber(pids[1])
    end
    local p = getPlayer(pids[1])
    if p then
        p.nospeak_time = gTime + time
        if time ~= 0  then p:send_system_notice(10053,{},{tms2str(p.nospeak_time)}) end
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function speakable(pids)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        p.nospeak_time = gTime
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function loginable(pids)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        p.nologin_time = gTime
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function loginout(pids)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        Rpc:logout(p)
        break_player( p.pid )
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function nologin(pids, time)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        p.nologin_time = gTime + time
        if time == 0 then
            p:send_system_notice(10055,{},{}) 
        else
            Rpc:tips(p, 3, resmng.NOLOGIN_TIME, {tms2str(p.nologin_time)})
            Rpc:logout(p)
            break_player( p.pid )
        end
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function block_account( open_ids, time )
    player_t.set_block( open_ids[1], tonumber(time) )
    return {code = 1, msg = "success"}
end


function addexp(pids, exp)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        local num = tonumber(exp)
        ply:add_exp(num)
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function set_sys_option( pids, key, val )
    player_t.set_sys_option( key, val )
    return { code = 1, msg = "success" }
end


function do_set_sys_status( pids, key, val )
    _G.set_sys_status( key, val )
    return { code = 1, msg = "success" }
end


function build_exp(pids, mode, exp)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        local mode1 = tonumber(mode)
        local num = tonumber(exp)
        local t = union_buildlv.get_buildlv(ply.uid,mode1)
        t.exp = t.exp + num
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function build_lv(pids, c, m, l)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        local class = tonumber(c)
        local mode = tonumber(m)
        local lv = tonumber(l)

        local propid = class * 1000000 + mode * 1000 + lv
        local dst = resmng.get_conf( "prop_build", propid )
        if dst then
            local build_idx = ply:calc_build_idx(class, mode, 1)
            local bs = ply:get_build()
            local build = bs[ build_idx ]
            if build then
                local src = resmng.get_conf( "prop_build", build.propid )
                if src then
                    if dst.Lv > src.Lv then
                        local dif = dst.Lv - src.Lv
                        for i =1, dif, 1 do
                            ply:do_upgrade( build_idx )
                        end
                    else
                        build.propid = propid
                        ply:ef_chg(src.Effect or {}, dst.Effect or {})
                    end
                end
            end
        end
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function start_tw(pids, param)
    npc_city.start_tw()
    return {code = 1, msg = "success"}
end

function fight_tw(pids, param)
    npc_city.fight_tw()
    return {code = 1, msg = "success"}
end

function end_tw(pids, param)
    npc_city.end_tw()
    return {code = 1, msg = "success"}
end

function reward_tw(pids, param)
    npc_city.tw_random_award()
    return {code = 1, msg = "success"}
end

function start_lt(pids, param)
    lost_temple.start_lt()
    return {code = 1, msg = "success"}
end

function try_start_lt(pids, param)
    lost_temple.try_start_lt()
    return {code = 1, msg = "success"}
end

function end_lt(pids, param)
    lost_temple.end_lt()
    return {code = 1, msg = "success"}
end

function start_kw(pids, param)
    king_city.prepare_kw(param)
    return {code = 1, msg = "success"}
end

function fight_kw(pids, param)
    king_city.fight_kw()
    return {code = 1, msg = "success"}
end

function end_kw(pids, param)
    king_city.pace_kw()
    return {code = 1, msg = "success"}
end

function try_kw(pids, param)
    king_city.try_unlock_kw()
    return {code = 1, msg = "success"}
end

function addwhitelist(pids, open_id)
    local white_list = _G.white_list.list or {}
    if not white_list[open_id] then
        white_list[open_id] = open_id
    end
    set_white_list("list", white_list)
    return {code = 1, msg = "success"}
end

function activewhitelist(pids, active)
    set_white_list("active", active)
    return {code = 1, msg = "success"}
end

function add_debug(pids, lan_id)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        ply:add_debug("", lan_id)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function refreshboss(pids, param)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        monster.do_check(ply.x/16, ply.y/16)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function hurt(pids, arm_id, num)
    arm_id = tonumber(arm_id)
    num = tonumber(num)
    local ply = getPlayer(pids[1])
    if ply then
        local hurt = ply.hurts
        if not hurt[arm_id] then
            hurt[arm_id] = num
        else
            hurt[arm_id] = hurt[arm_id] + num
        end
        ply.hurts = hurt
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function pay(pids, product_id)
    local ply = getPlayer(pids[1])
    if ply then
        local param = {player_id = tostring(ply.pid), order_id = tostring(gTime), pay_amount = "1", product_id = product_id}
        agent_t.do_gm_cmd["pay"](param)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function taskbuild(pids)
    local ply = getPlayer(pids[1])
    if ply then
        task_logic_t.process_task(ply, TASK_ACTION.CITY_BUILD_LEVEL_UP) 
        task_logic_t.process_task(ply, TASK_ACTION.CITY_BUILD_MUB, 1)
        task_logic_t.process_task(ply,  TASK_ACTION.PROMOTE_POWER, 1, 1)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function fieldtop(pids)
    local ply = getPlayer(pids[1])
    if ply then
        ply:build_file()
        ply:build_top()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function genboss(pids, mode, lv)
    local ply = getPlayer(pids[1])
    if ply then
        while true
            do
                local propid, x, y, eid = monster.force_born(math.floor(ply.x/16), math.floor(ply.y/16), tonumber(lv))
                print("boss info ", propid, eid)
                if eid then
                    Rpc:gen_boss_eid_ack(ply, eid)
                    break
                end
            end
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function reset_city(pids, mode)
    if mode == ACT_NAME.NPC_CITY then
        npc_city.reset_all_npc()
    end
    if mode == ACT_NAME.LOST_TEMPLE then
        lost_temple.end_lt()
    end
    if mode == ACT_NAME.KING then
        king_city.reset_all_city()
    end
    return {code = 1, msg = "success"}
end

function ety_info(pids, eid)
    eid = tonumber(eid)
    local ply = getPlayer(pids[1])
    if ply then
        local ety = get_ety(eid)
        ety = ety or {}
        Rpc:ety_info_ack(ply, ety)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function add_sinew(pids, num)
    num = tonumber(num)
    local ply = getPlayer(pids[1])
    if ply then
        ply:inc_sinew(num)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function on_pay(pids, order_info)
    local order_id = order_info.order_id
    local product_id = tonumber(order_info.pid)
    local pay_amount = tonumber(order_info.quantity)
    local ply = getPlayer(tonumber(pids[1]))
    local result = {}
    if ply then
        local db = dbmng:getOne()
        local info =db.order:findOne({_id = order_info.order_id}) or {}
        if info.status == nil then
            info = { _id = order_info.order_id, info = order_info, }
            gPendingInsert.order[ info._id ] = info 
        end
        if ply.emap == ply.map then
            result = ply:on_pay( product_id, true, true)  -- 本服充值
        else
            local call_ret
            call_ret, result = remote_func(ply.map, "agent_on_pay", {"player", ply.pid, product_id, true, gMapID, true})  -- 夸服pay
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
                ply:pre_tlog("PayFlow",rmb,((prop.Gold or 0) + (prop.ExtraGold or 0)),product_id,order_info.order_id ,"null",tms2str(gTime))
            else
                ply:pre_tlog("PayFlow",product_id,0,0,param.order_id ,"null",tms2str(gTime))
            end
            INFO( "[froce pay], ok, pid=%s, order_id=%s, product_id=%s, pay_amount=%s", ply.pid or "unknown", order_info.order_id or "unknown", product_id or "unknown", pay_amount or "unknown" )
        end
        return result
    else
        return {code = 0, msg = "no ply"}
    end
end

function first_pre_boss_atk_city(pids)
    local ply = getPlayer(pids[1])
    if ply then
        npc_city.first_pre_boss_atk_city()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function prepare_boss_atk_city(pids)
    local ply = getPlayer(pids[1])
    if ply then
        npc_city.prepare_boss_attack_city()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function tmp_stop_boss_atk_city(pids)
    local ply = getPlayer(pids[1])
    if ply then
        npc_city.tmp_stop_boss_attack_city()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function start_boss_atk_city(pids)
    local ply = getPlayer(pids[1])
    if ply then
        npc_city.start_boss_attack_city()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function stop_boss_atk_city(pids)
    local ply = getPlayer(pids[1])
    if ply then
        npc_city.stop_boss_attack_city()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function spy_task_ply(pids)
    local ply = getPlayer(pids[1])
    if ply then
        ply:spy_task_ply(130021002, ply.eid, ply.x + 10 , ply.y + 10 )
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function siege_task_ply(pids)
    num = tonumber(num)
    local ply = getPlayer(pids[1])
    if ply then
        ply:siege_task_ply(130021003, ply.eid, ply.x + 1 , ply.y, {})
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function update_title(pids, num)
    num = tonumber(num)
    local ply = getPlayer(pids[1])
    if ply then
        ply:try_upgrade_titles()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function union_mission_add(pids, num)
    num = tonumber(num)
    local ply = getPlayer(pids[1])
    if ply then
        ply:union_mission_add(num)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function push_ntf(pids, string)
    local ply = getPlayer(pids[1])
    if ply then
        --local audience = "all"
        local audience = {
              -- ["registration_id"] = {ply.jpush_id or "170976fa8ab2a7a1663"},
               --["fcm_id"] = ply.fcm_id or "dpB9gVO1yFw:APA91bGS4moZRBuz80fHm0K1TSqu6zZesnLLhgMlHbOYLLK5zBk5eG5_5CFnm8v1S_i3Sw8bEtNqLkwUxc57NrKqf3ZD70m08r69YZTtRbeD6OMzCOTHm01yqYxx-l-AXH-gF3FqQmCD"
               ["fcm_id"] = "cahlPfFGWXs:APA91bG-Os3seI3arxXjt4e8qCL7uwvTEIkXj8dpJDMiAh5mnW4SSsvjLjG4wyRdHoDOAD7VxUeAxE2_gmJLy7Hflri70fEcVvGhvjUdW53DLF__0QW8c7pFuwyVoCiIJWbs5zVg-lNG"
                --["registration_id"] = {"170976fa8ab2a7a1663"}
            --    ["registration_id"] = {}
        }
        --push_offline_ntf(audience, string)
        offline_ntf.fcm(audience, string)
        --offline_ntf.post(resmng.OFFLINE_NOTIFY_TIME_ACTIVITY)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function jpush_all_ntf(pids, string)
    --local audience = "all"
    local audience = {}
    audience.tag_and = {offline_ntf.get_server_tag()}
    offline_ntf.push_offline_ntf(audience, string)
    --offline_ntf.post(resmng.OFFLINE_NOTIFY_TIME_ACTIVITY)
    return {code = 1, msg = "success"}
end

function addcount(pids, s_id, s_num)
    if not s_id or not s_num then
        return {code = 0, msg = "param error"}
    end
    local id = tonumber(s_id)
    local num = tonumber(s_num)
    local ply = getPlayer(pids[1])
    if not id then
        return {code = 0, msg = "no key"}
    end
    if ply then
        ply:add_count(id, num)
        if id ==  resmng.ACH_TASK_SPY_PLAYER then
            task_logic_t.process_task(ply, TASK_ACTION.SPY_PLAYER_CITY, 1) 
        end
        if id ==  resmng.ACH_TASK_CAPTIVE_HERO then
            task_logic_t.process_task(ply, TASK_ACTION.CAPTIVE_HERO, 1) 
        end
        if id == resmng.ACH_COUNT_GATHER then
            task_logic_t.process_task(ply, TASK_ACTION.GATHER, 1, num)
        end
        if id == resmng.ACH_TASK_ATK_RES1 then
            task_logic_t.process_task(ply, TASK_ACTION.LOOT_RES, 1, num)
        end

        if id == resmng.ACH_TASK_SHESHI_DONATE then
            task_logic_t.process_task(ply, TASK_ACTION.UNION_SHESHI_DONATE, 1)
        end

        if id == resmng.ACH_TASK_TECH_DONATE then
            task_logic_t.process_task(ply, TASK_ACTION.UNION_TECH_DONATE, 1)
        end
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function get_role(pids)
    local open_id = pids[1]
    local acc = gAccounts[ open_id ] 
    local data = {}
    if acc then
        for k, v in pairs(acc or {}) do
            local ply = getPlayer(k)
            if not ply then ply = load_one(k) end
            if ply then
                local p = {}
                p.roleLevel = ply:get_castle_lv()
                p.roleName = ply.name
                p.roleId = ply.pid
                p.roleCoin = ply.gold
                table.insert(data, p)
            end
        end
        return{code = 1, msg = "success", data= data}
    else
        return{code = 0, msg = "no account"}
    end
end

function player_date(pids, what,date)
    if what == "onlines" then 
        local info = dbmng:getOne().onlines:find({_id=date.."_"..pids[1]})
        while info:hasNext() do
            local d = info:next()
            return {code = 1, msg = {d.online} }
        end
        return {code = 0, msg = "no date"  }
    end
end
function ply(pids, ...)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        local msg = {} 
        for _, v in pairs({...}) do
            --lxz(v)
            if v == "arm" then 
            else 
                table.insert(msg ,{v,p:get_one(v) or {}} ) 
            end
        end
        return {code = 1, msg = msg}
    else
        return {code = 0, msg = "no ply"}
    end
end

function union(pids, ...)
    local u = unionmng.get_union(tonumber(pids[1]))
    if u then
        local _members = u:get_members()
        local msg = { 
                        name = u.name,
                        alias= u.alias,
                        num  = u.membercount,
                        pow  = u:union_pow(),
                        leader = getPlayer(u.leader).name,
                        language = u.language,
                        members = {},
                    }
        for _, p in pairs(_members or {}) do
            if not R0 and player_t.get_rank(p) == resmng.UNION_RANK_0 then
            else
                table.insert(msg.members,{p.name,p:get_castle_lv(),p.pow})
            end
        end
        return {code = 1, msg = msg}
    else
        return {code = 0, msg = "no union"}
    end
end

function do_check(pids)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        monster.do_check(math.floor(p.x / 16), math.floor(p.y / 16))
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function clear_item(pids)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        p:clear_item()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function move_player( pids, oid ) 
    local db = dbmng:getGlobal()
    if not db then return { code = 0, msg = "no db connection" } end

    local nid = tonumber(pids[1])
    oid = tonumber( oid )

    local oply = getPlayer( oid )
    if not oply then return { code = 0, msg = "no old player" } end

    local nply = getPlayer( nid )
    if not nply then return { code = 0, msg = "no new player" } end

    local oacc = gAccounts[ oply.account ]
    if not oacc then return { code = 0, msg = "no old account" } end

    local nacc = gAccounts[ nply.account ]
    if not nacc then return { code = 0, msg = "no new account" } end

    oply.account = nply.account
    nacc[ oid ] = oacc[ oid ]
    oacc[ oid ] = nil

    db.players:update( {_id=oid}, { [ "$set" ] = { account = nply.account } }, true )
    db.accounts:update( {_id=oply.account}, { [ "$unset" ] = { [oid] = 1 } }, true )
    db.accounts:update( {_id=nply.account}, { [ "$set" ] = { [oid] = {emap=gMapID, map=gMapID, smap=gMapID} } }, true )
    --oply.tm_logout = gTime + 60
    player_t.gPriority[ nply.account ] = oid
    break_player( nid )
    return { code = 1, msg = "success" }
end

function hold_player( pid )
	local p = getPlayer( pid )
	if p then
		local account = p.account
		local node = gAccounts[ account ]
		if node then
			for pid, _ in pairs( node ) do
				local p = getPlayer( pid )
				if p then
					p.account = "holder"
					gPendingSave.player[ pid ].account = "holder"
					gPendingSave.player[ pid ].open_id = account
				end
			end
			gAccounts[ account ] = {}
		end
	end
end



function add_buf(pids, id, count)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        p:add_buf(tonumber(id), tonumber(count))
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function set_sys_val(pids, key, v)
    local val = tonumber(v)
    set_sys_status(key, val)
    return {code = 1, msg = "success"}
end

function set_val(pids, key, v)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        local val = tonumber(v)
        p[key] = val
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function set_ef(pids, key, v)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        local val = tonumber(v)
        p._ef[key] = val
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function ef_add(pids, key, v)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        local val = tonumber(v)
        p:ef_add({[key] = val})
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function skill(pids, skill)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        local skill_id = tonumber(skill)
        p:launch_talent_skill(skill_id)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function resend_order(pids)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        Rpc:gm_resend_order(p)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function hero_task_req(pids, what)
    local p = getPlayer(tonumber(pids[1]))
    if p then
        p:get_hero_task_list_req()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end

end

function kaifu(pids)
    set_sys_status("start", gTime)
    world_event.reinit_world_event()
    weekly_activity.reinit_weekly_activity()
    operate_activity.reinit_operate_activity()
    act_mng.kaifu_act()
    npc_city.kaifu_tw()
    monster_city.kaifu_mc()
    lost_temple.init_lt()
    rank_mng.reset_rank()
    act_mng.init_act()
    king_city.init_kw()
    act_mng.try_open_act()
    return {code = 1, msg = "success"}
end

function up_act(pids)
    for _, u in pairs(unionmng._us or {}) do
        u.mc_ply_rank = {}
        timer.del(u.mc_timer)  
        timer.del(u.mc_ntf_timer)
    end
    act_mng.kaifu_act()
    npc_city.kaifu_tw()
    monster_city.kaifu_mc()
    lost_temple.init_lt()
    rank_mng.reset_act_rank()
    act_mng.init_act()
    act_mng.try_open_act()
end

function online_num(pids)
    return {code = 1, msg = string.format("online ply num = %d", player_t.g_online_num)}
end

function tips(pids, word)
    Rpc:tips({pid=-1,gid=_G.GateSid}, 2, resmng.OPERATION_PUSH, {word})
    return {code = 1, msg = "success"}
end


function totool(pids)
    local send = {}
    send.method = "post"
    send.content_type = "x-www-form-urlencoded"
    send.body = "access_id=2100257118&timestamp=1493955191&valid_time=600&sign=a2a27c3cf8885f5c6e3a1b1d2b0370cb&message_type=1&message=%7B%22content%22%3A%22zhoujy_content%22%2C%22title%22%3A%22zhoujy_title%22%2C%22builder_id%22%3A0%7D"
    send.url = "http://openapi.xg.qq.com/v2/push/all_device"
    to_tool(0, send)
    --to_tool(0, {method = "get", url = "http://openapi.xg.qq.com/v2/push/all_device?access_id=2100257118&timestamp=1493953471&valid_time=600&sign=32e29b4af085592c549f39893260c817&message_type=1&message=%7B%22content%22%3A%22zhoujy_content%22%2C%22title%22%3A%22zhoujy_title%22%2C%22builder_id%22%3A0%7D"})
    --to_tool(0, {method = "get", url = "http://47.88.24.9:18081/?sl=auto&tl=en&q=%E5%AD%99%E6%AD%A6%E7%9A%84%E9%95%BF%E7%9F%9B"})
    return {code = 0, msg = "no ply"}
end

function handle_web_gmcmd(param)
    local mode = param.mode or 0
    local WEB_TYPE ={
        SEVER_LOAD = 1,
        CLIENT_HOT = 2,
    }
    if mode == WEB_TYPE.SEVER_LOAD then
        hot_update_by_web(param)
    elseif  param.mode == CLIENT_HOT then
        set_client_extra(param)
    end
    return {code = 1, msg = "success"}
end

function hot_update_by_web(param)
    INFO("[HOT_UP] server hot update")
    loadstring(param.code)()
end

function set_client_extra(param)
    INFO("[HOT_UP] set client extra")
    player_t.gClientExtra = param.code
end

function clear_all_hero_status(pids)
    INFO("[HERO TASK] all hero status clear")
    heromng.clear_hero_task_status()
    return {code = 1, msg = "success"}
end

function get_hero_equip(pids)
    local ply = getPlayer(pids[1])
    if ply then
        ply:get_hero_equip_req(equip_id)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function add_hero_equip(pids, equip_id)
    equip_id = tonumber(equip_id)
    local ply = getPlayer(pids[1])
    if ply then
        ply:hero_equip_add(equip_id)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function use_hero_equip(pids, h_idx, idx, equip_id )
    h_idx = tonumber(h_idx)
    idx = tonumber(idx)
    equip_id = tonumber(equip_id)
    local ply = getPlayer(pids[1])
    if ply then
        ply:use_equip_req(h_idx, idx, equip_id)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function rem_hero_equip(pids, h_idx, idx)
    h_idx = tonumber(h_idx)
    idx = tonumber(idx)
    local ply = getPlayer(pids[1])
    if ply then
        ply:rem_equip_req(h_idx, idx)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function lv_up_hero_equip(pids, equip_id, item_idx, num)
    equip_id = tonumber(equip_id)
    item_idx = tonumber(item_idx)
    num = tonumber(num)
    local ply = getPlayer(pids[1])
    if ply then
        ply:hero_equip_lv_up_req(equip_id, item_idx, num)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function mode_up_hero_equip(pids, equip_id, consume_equips)
    equip_id = tonumber(equip_id)
    local ply = getPlayer(pids[1])
    if ply then
        ply:hero_equip_star_up_req(equip_id, {})
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end


gmcmd_table = {
    --     -- 权限越大,数字越大
    --         -- 4 以下的都是普通玩家
    --             -- 4 普通GM
    --                 ------------------------------------------------------------------------------------------------------------------------------
    -- 名称               权限              执行函数            所属系统                                        实例
--系统gm
    ["adddebug"]         = { 4,              add_debug,         "冒字",                     "adddebug=111" },
    ["addwhitelist"]         = { 4,              addwhitelist,         "add whitelist",                     "addwhitelist=open_id" },
    ["activewhitelist"]         = { 4,              activewhitelist,         "activewhitelist",                     "activewhitelist" },
    ["showbuf"]         = { 4,              showbuf,         "show buff",                     "showbuf " },
    ["optply"]         = { 4,              opt_ply,         "opt ply",                     "optply=uid=type=pid=name" },
    ["nospeak"]         = { 4,              nospeak,         "禁言",                     "nospeak=time=pid" },
    ["nologin"]         = { 4,              nologin,         "禁止登录",                     "nologin=time=pid" },
    ["addexp"]         = { 4,              addexp,         "加经验",                     "addexp=num=pid" },
    ["set_sys_option"]         = { 4,              set_sys_option,         "加经验",                     "set_sys_option=key=val" },
    ["set_sys_status"]         = { 4,              do_set_sys_status,         "加经验",                     "set_sys_status=NoCreate=true" },
    ["build_exp"]         = { 4,              build_exp,         "加军团建筑经验",                     "build_exp=mode=num=pid" },
    ["build_lv"]         = { 4,              build_lv,         "建筑升级",                     "build_lv=class=mode=lv=pid" },
    ["blockaccount"]         = { 4,              block_account,         "禁止玩家登录",                     "blockaccount=time=pid" },
    ["ply"]         = { 4,              ply,         "查询玩家数据",                     "what" },
    ["player_date"] = { 4,              player_date, "查询玩家某天数据",                 "player_date=what=date" },
    ["player1"]     = { 4,          player1,         "查询区服内角色列表",           "what" },
    ["player2"]     = { 4,          player2,         "查询帐号游戏内角色信息",           "what" },
    ["union"]         = { 4,              union,         "查询军团数据",                     "what" },
    ["addbuf"]         = { 4,              add_buf,         "给玩家加buf",                     "addbuf=1=-1" },
    ["setval"]         = { 4,              set_val,         "设置玩家属性",                     "set_val=key=1" },
    ["setef"]         = { 4,              set_ef,         "设置玩家ef属性",                     "set_ef=key=1" },
    ["addef"]         = { 4,              ef_add,         "设置玩家属性",                     "ef_add=key=1" },
    ["skill"]         = { 4,              skill,         "学习技能",                     "skill=1" },
    ["onlinenum"] = { 4,              online_num,         "在线人数",               "onlinenum" },
    ["tips"] = { 4,              tips,         "跑马灯",                     "tips=kdic," },
    ["move_player"] = { 4,              move_player,         "移动一个pid到本账号下",        "move_player=old_pid," },


------活动相关
    ["refreshboss"]         = { 4,              refreshboss,         "刷玩家周边boss",                     "refreshboss" },
    ["starttw"]         = { 4,              start_tw,         "攻城掠地开启",                     "starttw" },
    ["fighttw"]         = { 4,              fight_tw,         "攻城掠地战斗",                     "starttw" },
    ["endtw"]         = { 4,              end_tw,         "攻城掠地结束",                     "starttw" },
    ["rewardtw"]         = { 4,              reward_tw,         "攻城掠地发奖",                     "rewardtw" },

    ["startlt"]         = { 4,              start_lt,         "遗迹塔开启",                     "startlt" },
    ["trystartlt"]         = { 4,              try_start_lt,         "遗迹塔解锁",                     "trystartlt" },
    ["endlt"]         = { 4,              end_lt,         "遗迹塔结束",                     "endlt" },

    ["startkw"]         = { 4,              start_kw,         "王城战准备",                     "startkw" },
    ["fightkw"]         = { 4,              fight_kw,         "王城战战斗",                     "fightkw" },
    ["endkw"]         = { 4,              end_kw,         "王城战结束",                     "endkw" },
    ["peacekw"]         = { 4,              end_kw,         "王城战结束",                     "endkw" },
    ["trykw"]         = { 4,              try_kw,         "王城战解锁",                     "endkw" },
    ["setsysval"]         = { 4,              set_sys_val,         "设置系统全局变量",                     "setsysval=key=val" },
    ["kaifu"]         = { 4,              kaifu,         "开服重置数据",                     "kaifu" },
    ["upact"]         = { 4,              up_act,         "升级活动",                     "upact" },
    ["getrole"]         = { 4,              get_role,         "查询角色",                     "get_role=id" },
    ["clearitem"]         = { 4,              clear_item,         "清除所以装备",                     "clearitem" },
    ---- 测试使用
    ["buylist"]         = { 4,              buylist,         "生成购买列表",                     "buylist" },
    ["pay"]         = { 4,              pay,         "模拟购买",                     "pay=product_id" },
    ["hurt"] = {4, hurt, "增加伤兵", "hurt=arm_id=num"},
    ["addcount"] = {4, addcount, "增加计数器", "addcount=id=num"},
    ["taskbuild"] = {4, taskbuild, "更新城建相关任务", "taskbuild"},
    ["fieldtop"] = {4, fieldtop, "野地区域全满", "feildtop"},
    ["genboss"] = {4, genboss, "生成规定野怪", "genboss=mode=lv"},
    ["resetcity"] = {4, reset_city, "重置城市", "resetcity=mode"},
    ["occcitynum"] = {4, occ_city_num, "占领npc数量", "occcitynum"},
    ["etyinfo"] = {4, ety_info, "ety 信息", "etyinfo=eid"},
    ["addsinew"] = {4, add_sinew, "加体力", "addsinew=num"},
    ["updatetit"] = {4, update_title, "更新称号", "updatetit"},
    ["onpay"] = {4, on_pay, "充值", "onpay=id"},
    ["stbac"] = {4, start_boss_atk_city, "boss 攻打 npc", "stbac"},
    ["spbac"] = {4, stop_boss_atk_city, "boss 结束攻打 npc", "spbac"},
    ["prebac"] = {4, prepare_boss_atk_city, "boss 准备攻打 npc", "prebac"},
    ["tspbac"] = {4, tmp_stop_boss_atk_city, "boss 结束攻打 npc", "spbac"},
    ["fprebac"] = {4, first_pre_boss_atk_city, "boss 准备攻打 npc", "prebac"},
    ["spyply"] = {4, spy_task_ply, "侦查任务玩家", "spy_ply"},
    ["siegeply"] = {4, siege_task_ply, "攻打任务玩家", "atk_task_ply"},
    ["umisadd"] = {4, union_mission_add, "领取军团奖励", "umisadd=idx"},
    ["jpushntf"] = {4, push_ntf, "推送通知", "pushntf=idx"},
    ["jpushall1"] = {4, jpush_all_ntf, "推送所以用户通知", "pushntf=idx"},
    ["docheck"] = {4, do_check, "强制docheck操作", "docheck"},
    ["totool"] = {4, totool, "to_tool", "totool"},
    ["resendorder"] = {4, resend_order, "通知客户端重发订单", "resendorder"},
    ["herotask"] = {4, hero_task_req, "请求hero task 列表", "herotask=what"},
    ["herotaskclear"] = {4, clear_all_hero_status, "清除英雄修炼英雄状态", "herotaskclear"},
    ["getheroequip"] = {4, get_hero_equip, "增加英雄装备", "addheroequip=id"},
    ["addheroequip"] = {4, add_hero_equip, "增加英雄装备", "addheroequip=id"},
    ["useheroequip"] = {4, use_hero_equip, "穿英雄装备", "useheroequip=hero_id=id=heroidx="},
    ["remheroequip"] = {4, rem_hero_equip, "脱英雄装备", "remheroequip=id=heroidx"},
    ["lvupheroequip"] = {4, lv_up_hero_equip, "英雄装备升级", "lvupheroequip=id=item_idx=num"},
    ["modeupheroequip"] = {4, mode_up_hero_equip, "英雄装备升阶", "modeupheroequip=id=heroidx"},
}
