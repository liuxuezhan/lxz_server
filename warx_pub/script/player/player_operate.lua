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
            --WARN( "update %d operate_activity", p.pid )
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
            if b then
                if b.activity_id == "_op_data" then
                    b.activity_id = "op_data"
                end
                if b.activity_id == "op_data" then
                    for k, v in pairs(b or {}) do
                        local val = v
                        if type(k) == "number" then
                            local prop_tab = resmng.get_conf("prop_operate_activity", k)
                            if prop_tab then
                                val = operate_activity.get_obj_by_type(prop_tab.Type, v)
                            end
                        end
                        b[k] = val
                    end
                end
            end
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
            gPendingSave.operate_activity[node._id]  = node
        end
        return node
    else
        return self._operate_activity
    end
end

function updata_single_op_data(self, activity_id, data)
    if activity_id then
        local datas = self:get_operate_activity()
        if datas["op_data"] == nil then
            self:get_single_op_data( activity_id)
        end
        gPendingSave.operate_activity[datas._id][activity_id] = data
    end
end

function get_single_op_data(self, activity_id)
    if activity_id then
        local prop_tab = resmng.get_conf("prop_operate_activity", activity_id)
        local data = operate_activity.OpActivityData[activity_id]
        if prop_tab.Type ==  OPERATE_ACTIVITY_TYPE.PERSON then
            local datas = self:get_operate_activity()
            if datas["op_data"] == nil then
                datas["op_data"] = {_id=self.pid.."_op_data", pid=self.pid, activity_id="op_data"}
                gPendingSave.operate_activity[datas.op_data._id] = datas["op_data"]
            end
            if datas["op_data"][activity_id] == nil then
                if operate_activity.OpActivityData[activity_id] then
                    local data1 = operate_activity.get_obj_by_type(prop_tab.Type, data)
                    local start_tab = prop_tab.StartTime
                    local class = start_tab[1]
                    if class == "tmcreate" then
                        local st_tm = get_zero_tm(self.tm_create)
                        data1.start_time = st_tm + start_tab[2]
                        data1.end_time = data1.start_time + prop_tab.Duration
                        if prop_tab.Circulation ~= nil and data1.end_time <= gTime then
                            local period = prop_tab.Duration + prop_tab.Circulation
                            local span = gTime - self.end_time
                            data1.start_time = data1.start_time + math.floor(span / period) * period
                            data1.end_time = data1.start_time + prop_tab.Duration
                        end
                    end
                    data1:tick()
                    datas["op_data"][activity_id] = data1
                    gPendingSave.operate_activity[datas.op_data._id][activity_id] = data1
                end
            end
            return  datas["op_data"][activity_id]
        else
            return data
        end
    else
        return 
    end
end

function get_op_activity_data(self, activity_id)
    if activity_id then
        return self:get_single_op_data(activity_id)
    else
        local datas = {}
        for k, v in pairs(operate_activity.OpActivityData or {}) do
            local prop_tab = resmng.get_conf("prop_operate_activity", k)
            if prop_tab.Type ==  OPERATE_ACTIVITY_TYPE.PERSON then
                datas[k] = self:get_single_op_data(k)
            else
                datas[k] = v
            end
        end
        return datas
    end
end

function get_operate_info(p, activity_id, class)
    local d = get_operate_activity(p,activity_id)
    return d[class]
end

function on_check_pending_oparate_activity(db, id, chgs)
    local list = string.split(id, "_")
    local ply = getPlayer(tonumber(list[1]))
    if ply then
        if list[2] == "op" then
            list[2] = "op_data"
        else
            list[2] = tonumber(list[2])
        end
        local d = ply:get_operate_activity(list[2])
        if d then
            Rpc:operate_activity_update_data(ply, { d } )
        end
    end
end

registe_update_callback("operate_activity", player_t.on_check_pending_oparate_activity)

function set_operate_version(p, activity_id, version)
    local d = get_operate_activity(p,activity_id)
    d[OPERATE_PLAYER_DATA.VERSION] = version
    gPendingSave.operate_activity[d._id][OPERATE_PLAYER_DATA.VERSION]  = version 
end

function set_operate_first_flag(p, activity_id)
    local d = get_operate_activity(p,activity_id)
    d[OPERATE_PLAYER_DATA.FIRST_FLAG] = true
    gPendingSave.operate_activity[d._id][OPERATE_PLAYER_DATA.FIRST_FLAG]  = true 
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
        local activity = operate_activity.get_activity_by_id(p, activity_id)
        if activity ~= nil then
            d[OPERATE_PLAYER_DATA.VERSION] = activity.version
            gPendingSave.operate_activity[d._id][OPERATE_PLAYER_DATA.VERSION] = activity.version 
        end
    end
    gPendingSave.operate_activity[d._id][class]  = d[class] 


end

function update_operate_info(p, activity_id, class, key, value)
    local d = get_operate_activity(p,activity_id)
    d[class] =  d[class] or {} 
    d[class][key] = value

    --活动计数标记赋值
    if d[OPERATE_PLAYER_DATA.VERSION] == nil then
        local activity = operate_activity.get_activity_by_id(p, activity_id)
        if activity ~= nil then
            d[OPERATE_PLAYER_DATA.VERSION] = activity.version
            gPendingSave.operate_activity[d._id][OPERATE_PLAYER_DATA.VERSION] = activity.version 
        end
    end
    p._operate_activity[activity_id] = d
    gPendingSave.operate_activity[d._id][class]  = d[class] 
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
            local activity = operate_activity.get_activity_by_id(p, id)
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
        elseif id == tostring(p.pid).."_op_data" then
            local need_save = false
            for k, v in pairs(d or {}) do
                if v:tick() then
                    need_save = true
                end
                if need_save then
                    gPendingInsert.operate_activity[d._id] = d
                end
            end
        end
    end
end

function operate_check_all_version(p)
    local oas = get_operate_activity( p )
    for id, d in pairs(oas or {}) do
        if type(id) == "number" then
            local activity = operate_activity.get_activity_by_id(p, id)
            if activity ~= nil then
                if d[OPERATE_PLAYER_DATA.VERSION] ~= nil then
                    if activity.version ~= d[OPERATE_PLAYER_DATA.VERSION] then
                        local t = {_id=p.pid.."_"..id,pid=p.pid,activity_id=id,[OPERATE_PLAYER_DATA.VERSION] = activity.version,}
                        oas[ id ] = t
                        gPendingInsert.operate_activity[t._id] = t  
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
        end
    end
end

