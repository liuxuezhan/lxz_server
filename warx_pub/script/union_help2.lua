
-- 军团帮助模块
module(..., package.seeall)

function add(p,tm_sn)
    local u = unionmng.get_union(p:get_uid())
    if not u  then return end

    if not u.help then u.help={} end

    if u.help[tm_sn] then 
        INFO("[UNION] union_help pid=%d, uid=%d, already req, sn=%d",p.pid,p.uid,tm_sn) 
        return 
    end

    local t = timer.get(tm_sn)
    if not t then 
        INFO("[UNION] union_help pid=%d, uid=%d, no timer, sn=%d",p.pid,p.uid,tm_sn) 
        return 
    end

    if (t.what =="build" or t.what =="cure") then
        local pid = t.param[1]
        local idx = t.param[2]
        local propid = t.param[3]
        local state = t.param[4]
        local extra = t.param[5]
        if p.pid == pid then
            local node = { id = tm_sn, info = { tm_sn, p.pid, p:get_val("CountHelp"), 0 }, logs = {} }
            if t.what == "build" then
                local build = p:get_build( idx )
                if build then node.build = build end
            end
            u.help[ tm_sn ] = node
            u:notifyall( resmng.UNION_EVENT.HELP, resmng.UNION_MODE.ADD, node.info )
            task_logic_t.process_task( p, TASK_ACTION.UNION_HELP_NUM, 1 )
        end
    end
end

function get_help_action( node )
    local aciton = node.action
    if action then return action end

    local tm_sn = node.id
    local t = timer.get( tm_sn )
    if not t then return end

    if (t.what =="build" or t.what =="cure") then
        local pid = t.param[1]
        local idx = t.param[2]
        local propid = t.param[3]
        local state = t.param[4]
        local extra = t.param[5]

        local w = getPlayer( pid )
        if w then
            local op = {}
            op.what = t.what
            op.tm = w:get_val( "TimeHelp" )

            if t.what == "cure" then
                op.tips = resmng.UNION_BEHELPED_TYPE_HEAL
                op.param = {}
            else
                local c = resmng.get_conf( "prop_build", propid )
                if state == BUILD_STATE.UPGRADE then
                    op.tips = resmng.UNION_BEHELPED_TYPE_BUILD 
                    op.param = {"name", c.name, c.Lv+1}

                elseif state == BUILD_STATE.CREATE then
                    op.tips = resmng.UNION_BEHELPED_TYPE_BUILD 
                    op.param = {"name", c.name, c.Lv }

                elseif state == BUILD_STATE.WORK then
                    if c.Class == BUILD_CLASS.FUNCTION then
                        if c.Mode == BUILD_FUNCTION_MODE.FORGE then
                            local id = extra.forge
                            local econf = resmng.get_conf( "prop_equip", id )
                            if econf then
                                op.tips = resmng.UNION_BEHELPED_TYPE_EQUIP
                                op.param = { "name", econf.Name, econf.Lv }
                            end
                        elseif c.Mode == BUILD_FUNCTION_MODE.ACADEMY then
                            local id = extra.id
                            local econf = resmng.get_conf( "prop_tech", id )
                            if econf then
                                op.tips = resmng.UNION_BEHELPED_TYPE_TECH
                                op.param = { "name", econf.Name, econf.Lv }
                            end
                        end
                    end
                end
            end

            if op.tips then
                node.action = op
                return op
            end
        end
    end
end

function set_one( p, sn )
    local u = unionmng.get_union(p:get_uid())
    if not u then return end
    if not u.help then return end

    local node = u.help[ sn ]
    if not node then return end

    local pid = p.pid
    if node.logs[ pid ] then return end

    local info = node.info
    if info[2] == pid then return end

    if info[4] >= info[3] then return end
    
    node.logs[ pid ] = gTime
    info[4] = info[4] + 1

    if info[4] >= info[3] then
        del( p, sn )
        u.help[ sn ] = node
    end

    local w = getPlayer( info[2] )
    if not w then return end

    local action = get_help_action( node )
    if not aciton then return end

    if action.what == "cure" then
        w:do_cure_acc( action.tm )
    else
        node.build:acceleration( action.tm )
    end
    local param = action.param
    param[1] = p.name
    Rpc:tips( w, action.tips, param )

    return true
end


function set(p,id)
    local u = unionmng.get_union(p:get_uid())
    if not u then return end
    if not u.help then return end

    local pid = p.pid
    if id == 0 then
        local count = 0
        for k, v in pairs( u.help ) do
            if v.log and v.log[ pid ] then 
                -- already help
            else
                if set_one(p,k) then count = count + 1 end
            end
        end

        if count > 0 then
            union_mission.ok(p,UNION_MISSION_CLASS.HELP,count)
            task_logic_t.process_task(p, TASK_ACTION.UNION_HELP_NUM, count)
        end
    else
        local v = u.help[ id ]
        if not v then return end
        if v.pid == pid then return end
        if v.log and v.log[ pid ] then return end

        if set_one(p,k) then
            union_mission.ok(p,UNION_MISSION_CLASS.HELP, 1)
            task_logic_t.process_task(p, TASK_ACTION.UNION_HELP_NUM, 1)
        end
    end
end

function get(p)
    local l  = {}
    local u = unionmng.get_union(p:get_uid())
    if u then
        local dels = {}
        for k, v in pairs(u.help or {}) do
            if timer.get( k ) then
                if not v.log[p.pid] then 
                    local info = v.info
                    if info[2] == p.pid then
                        -- for the owner do not call help duplicate
                        table.insert( l, info )
                    else
                        if info[3] > info[4] then
                            table.insert( l, info )
                        end
                    end
                end
            else
                table.insert( dels, k )
            end
        end
        if #dels > 0 then
            for k, v in pairs( dels ) do
                del( p, v )
            end
        end
    end
    return l
end

function get_detail( p ) 
    local list = get( p )
    if #list > 0 then
        local infos = {}
        for _, v in pairs( list ) do
            local info = do_get_detail( v )
            if info then
                table.insert( infos, info )
            end
        end
        return infos
    end
    return {}
end

function do_get_detail(node)
    local t = timer.get(node.id)

    if not t then return end
    local pid = t.param[1]
    local idx = t.param[2]
    local propid = t.param[3]
    local state = t.param[4]

    local p = getPlayer(pid)
    if not p then return end

    local info = node.info

    if t.what == "build" then
        local d = {id=t._id, pid=p.pid, photo=p.photo, name = p.name, helped=t.is_help, limit=info[3], num=info[4], idx=idx }
        if state == BUILD_STATE.CREATE then
            d.type = HELP_TYPE.CONSTRUCT
            d.propid = propid
            return d

        elseif state == BUILD_STATE.UPGRADE then
            d.type = HELP_TYPE.UPGRADE
            d.propid = propid
            return d

        elseif state == BUILD_STATE.WORK then
            local conf = resmng.get_conf( "prop_build", propid )
            if conf then
                if conf.Class == BUILD_CLASS.FUNCTION then
                    local mode = conf.Mode
                    if mode == BUILD_FUNCTION_MODE.ACADEMY then
                        d.type = HELP_TYPE.RESEARCH
                        local extra = t.param[5]
                        d.propid = extra.id

                    elseif mode == BUILD_FUNCTION_MODE.HOSPITAL then
                        d.type = HELP_TYPE.HEAL

                    elseif mode == BUILD_FUNCTION_MODE.FORGE then
                        d.type = HELP_TYPE.CAST
                        local extra = t.param[5]
                        d.propid = extra.forge

                    else
                        return
                    end
                end
                return d
            end
        end

    elseif t.what == "cure" then
        local d = {id=t._id, pid=p.pid, photo=p.photo, name = p.name, helped=t.is_help, limit=info[3], num=info[4] }
        d.type = HELP_TYPE.HEAL
        return d

    end
end


function del(p,sn)
    if u and u.help then
        local node = u.help[ sn ]
        u.help[ sn ] = nil
        if node then
            local logs = node.logs
            local pids = {}
            for pid, p in pairs(u._members or {}) do
                if not logs[ pid ] then
                    if player_t.is_online( p ) then
                        table.insert( pids, pid )
                    end
                end
            end
            if #pids > 0 then
                Rpc:union_broadcast( pids, resmng.UNION_EVENT.HELP, resmng.UNION_MODE.DELETE, {id=sn} )
            end
        end
    end
end

