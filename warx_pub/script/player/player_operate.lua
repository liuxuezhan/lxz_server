module("player_t")

-- 玩家存储结构
-- player.operate_activity = 
-- {
--  [activity_id] = 
--  {
--      [OPERATE_PLAYER_DATA.VERSION] = 0
--      [OPERATE_PLAYER_DATA.EXCHANGE] = {id=num, id=num, id=num}
--      [OPERATE_PLAYER_DATA.ACTION] = {id=num, id=num, id=num}
--      [OPERATE_PLAYER_DATA.ACTION_AWARD] = {id=1, id=1}
--  }
-- }

function change_operate_activity()--转档
    for _, p in pairs( gPlys or {}) do
        if p._pro.operate_activity then
            local as = {}
            for k, v in pairs(p.operate_activity ) do
                if type(k) == "number" then
                    v._id = p.pid .. "_" .. k
                    v.pid = p.pid
                    v.activity_id = k
                    as[ k ] = v
                    gPendingInsert.operate_activity[v._id] = v 
                end
            end
            p._pro.operate_activity = nil
            rawset( p, "_operate_activity", as )
            WARN( "update %d operate_activity", p.pid )
        end
    end

    local db = dbmng:getOne()
    if db then
        db.player:update( {}, { ["$unset"]={ ["operate_activity"]='', } }, false, true )
    else
        ERROR( "change_operate_activity, can not get db" )
    end
end

function do_load_operate_activity( self )
    if not self._operate_activity then
        local bs = {}
        local db = self:getDb()
        local info = db.operate_activity:find({pid=self.pid})
        while info:hasNext() do
            local b = info:next()
            bs[ b.activity_id ] = b
        end
        if not self._operate_activity then rawset(self, "_operate_activity", bs) end
    end
end

function get_operate_activity( self, id )
    if not self._operate_activity then do_load_operate_activity( self ) end
    if id then
        local node = self._operate_activity[ id ]
        if not node then
            node =  {_id=self.pid.."_"..id,pid=self.pid,activity_id=id,}
            self._operate_activity[ id ] = node
        end
        return node
    else
        return self._operate_activity
    end
end

function get_operate_info(p, activity_id, class)
    local d = get_operate_activity(p,activity_id)
    return d[class]
end

function set_operate_version(p, activity_id, version)
    local d = get_operate_activity(p,activity_id)
    d[OPERATE_PLAYER_DATA.VERSION] = version
    gPendingSave.operate_activity[d._id][OPERATE_PLAYER_DATA.VERSION]  = version 
    if p then Rpc:operate_activity_update_data(p, { d } ) end
end

function set_operate_first_flag(p, activity_id)
    local d = get_operate_activity(p,activity_id)
    d[OPERATE_PLAYER_DATA.FIRST_FLAG] = true
    gPendingSave.operate_activity[d._id][OPERATE_PLAYER_DATA.FIRST_FLAG]  = true 
    if p then Rpc:operate_activity_update_data(p, { d } ) end
end

function get_operate_first_flag(p, activity_id)
    local d = get_operate_activity(p,activity_id)
    if d[OPERATE_PLAYER_DATA.FIRST_FLAG] then return true end
end

function set_operate_info(p, activity_id, class, key, value)
    local d = get_operate_activity(p,activity_id)
    d[class] =  d[class] or {} 
    d[class][key] = (d[class][key] or 0 ) + value

    --活动计数标记赋值
    if d[OPERATE_PLAYER_DATA.VERSION] == nil then
        local activity = operate_activity.get_activity_by_id(activity_id)
        if activity ~= nil then
            d[OPERATE_PLAYER_DATA.VERSION] = activity.version
            gPendingSave.operate_activity[d._id][OPERATE_PLAYER_DATA.VERSION] = activity.version 
        end
    end
    gPendingSave.operate_activity[d._id][class]  = d[class] 
    if p then Rpc:operate_activity_update_data(p, { d } ) end
end

function update_operate_info(p, activity_id, class, key, value)
    local d = get_operate_activity(p,activity_id)
    d[class] =  d[class] or {} 
    d[class][key] = value

    --活动计数标记赋值
    if d[OPERATE_PLAYER_DATA.VERSION] == nil then
        local activity = operate_activity.get_activity_by_id(activity_id)
        if activity ~= nil then
            d[OPERATE_PLAYER_DATA.VERSION] = activity.version
            gPendingSave.operate_activity[d._id][OPERATE_PLAYER_DATA.VERSION] = activity.version 
        end
    end
    p._operate_activity[activity_id] = d
    gPendingSave.operate_activity[d._id][class]  = d[class] 
    if p then Rpc:operate_activity_update_data(p, { d } ) end
end

--rpc
function operate_activity_list(p)
    get_operate_activity(p)
    p:operate_check_all_version()
    operate_activity.packet_activity_list(p)
end

function operate_exchange(p, activity_id, exchange_id)
    operate_activity.exchage(p, activity_id, exchange_id)
end

function operate_single_get(p, activity_id)
    operate_activity.single_get(p, activity_id)
end

function operate_task_get(p, activity_id, task_id)
    operate_activity.task_get(p, activity_id, task_id)
end

function operate_on_day_pass(p)
    local upds = {}
    for id, d in pairs(p._operate_activity or {}) do
        if type(id) == "number" then
            local activity = operate_activity.get_activity_by_id(id)
            if activity == nil or activity.is_end == 1 then
                table.insert( upds, { activity_id=id, delete=true} )
                p._operate_activity[id] = nil
                gPendingDelete.operate_activity[d._id] = 1  
            elseif nil ~= d[OPERATE_PLAYER_DATA.VERSION] then
                local prop = resmng.get_conf("prop_operate_activity", id)
                if prop.CirculationNum then
                    local t = {_id=p.pid.."_"..id,pid=p.pid,activity_id=id,[OPERATE_PLAYER_DATA.VERSION] = activity.version,}
                    p._operate_activity[id] = t 
                    gPendingInsert.operate_activity[t._id] = t  
                    table.insert( upds, t )
                end
            end
        end
    end
    if p then Rpc:operate_activity_update_data(p, upds ) end
end

function operate_check_all_version(p)
    local oas = get_operate_activity( p )
    for id, d in pairs(oas or {}) do
        if type(id) == "number" then
            local activity = operate_activity.get_activity_by_id(id)
            if activity ~= nil then
                if d[OPERATE_PLAYER_DATA.VERSION] ~= nil then
                    if activity.version ~= d[OPERATE_PLAYER_DATA.VERSION] then
                        local t = {_id=p.pid.."_"..id,pid=p.pid,activity_id=id,[OPERATE_PLAYER_DATA.VERSION] = activity.version,}
                        oas[ id ] = t
                        gPendingInsert.operate_activity[t._id] = t  
                        Rpc:operate_activity_update_data( p, { t } )
                    end
                end
            end
        end
    end
end

function operate_check_version(p, activity)
    if activity == nil then return end
    local id = activity.activity_id
    local d = get_operate_activity(p,id)
    
    if d[OPERATE_PLAYER_DATA.VERSION] ~= nil then
        if activity.version ~= d[OPERATE_PLAYER_DATA.VERSION] then
            local t = {_id=p.pid.."_"..id,pid=p.pid,activity_id=id,[OPERATE_PLAYER_DATA.VERSION] = activity.version,}
            p._operate_activity[id] = t 
            gPendingInsert.operate_activity[t._id] = t  
            Rpc:operate_activity_update_data( p, { t } )
        end
    end
end

