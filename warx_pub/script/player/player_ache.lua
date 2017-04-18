module("player_t")

function ache_info_req(self)
    local pack = {}
    local ache = self:get_count()
    if ache then
        pack.ache = ache
    end

    local ache_stat = self:get_ache()
    if ache_stat then
        pack.ache_stat = ache_stat
    end

    pack.ache_point = self.ache_point

    Rpc:ache_info_ack(self, pack)
    
end 

function try_add_tit_point(self, action)
    for k, v in pairs(resmng.prop_achievement or {}) do
        if v.Var == action then
            if not is_already_add_point(self, k) then
                self:add_tit_point(k)
            end
        end
    end
end

function get_ache_reward(self, idx)

    if is_already_ache(self, idx) then
        return
    end

    if self:gain_ache(idx) then
        local aconf = resmng.get_conf( "prop_achievement", idx )
        if not aconf then return end

        local reward = aconf.Reward
        if reward then
            self:add_bonus( "mutex_award", reward, VALUE_CHANGE_REASON.REASON_ACHE)
        end

        ache_info_req(self)
    end
end

function is_already_add_point(self, idx)
    local tit_point = self:get_tit_point()
    if tit_point[idx] then
        return true
    end
end

function is_already_ache(self, idx)
    local ache_stat = self:get_ache()
    if ache_stat[idx] then
        return true
    end
end

function do_load_ache( self )
    local db = self:getDb()
    local info = db.ache:findOne({_id=self.pid})
    return info or {}
end

function do_load_tit_point( self )
    local db = self:getDb()
    local info = db.tit_point:findOne({_id=self.pid})

    local point = 0   -- cal ache point  by ache status
    for k, v in pairs(info or {}) do
        if v ~= 0 then
            local aconf = resmng.get_conf( "prop_achievement", k )
            if aconf then
                point = point + aconf.Point
            end
        end
    end
    self.ache_point = point

    return info or {}
end

function get_tit_point(self, id)
    if not self._tit_point then self._tit_point = self:do_load_tit_point() end
    if id then return self._tit_point[ id ] else return self._tit_point end
end

function set_tit_point(self, key, val)
    val = val or gTime
    local tit_point = self:get_tit_point()
    tit_point[ key ] = val
    gPendingSave.tit_point[ self.pid ][key] = val
    --Rpc:set_ache( self, key, aches[ key ] )
end

function get_ache( self, id )
    if not self._ache then self._ache = self:do_load_ache() end
    if id then return self._ache[ id ] else return self._ache end
end

function set_ache( self, key, val)
    val = val or gTime
    local aches = self:get_ache()
    aches[ key ] = val
    gPendingSave.ache[ self.pid ][key] = val
    Rpc:set_ache( self, key, aches[ key ] )
end

function do_load_count( self )
    local db = self:getDb()
    local info = db.count:findOne({_id=self.pid})
    return self._count or info or {}
end

function get_count( self, id )
    if not self._count then self._count = self:do_load_count() end
    if id then 
        return self._count[ id ] or 0 
    else 
        return self._count 
    end
end

function add_count( self, key, val )
    val = math.floor( val or 1 )
    local counts = self:get_count()
    counts[ key ] = ( counts[ key ] or 0 ) + val
    gPendingSave.count[ self.pid ][key] = counts[ key ]
    try_add_tit_point(self, key)
    Rpc:set_count( self, key, counts[ key ] )
    if key == resmng.ACH_COUNT_KILL_POW then union_mission.ok(self,UNION_MISSION_CLASS.KILL,val) end
end

local func_ache = {}

function check_tit_point( self, idx )
    local point_state = self:get_tit_point()
    local ache = point_state[ idx ]
    if ache then return end

    local aconf = resmng.get_conf( "prop_achievement", idx )
    if not aconf then return end

    local var = aconf.Var
    local cconf = resmng.get_conf( "prop_achievement_var", var )
    if not cconf then return end

    local func = func_ache[ cconf.Way ]
    if not func then return end

    if func( self, var, cconf.Param ) >= aconf.Count then return aconf end
end

function check_ache( self, idx )
    local aches = self:get_ache()
    local ache = aches[ idx ]
    if ache then return end

    local aconf = resmng.get_conf( "prop_achievement", idx )
    if not aconf then return end

    local var = aconf.Var
    local cconf = resmng.get_conf( "prop_achievement_var", var )
    if not cconf then return end

    local func = func_ache[ cconf.Way ]
    if not func then return end

    if func( self, var, cconf.Param ) >= aconf.Count then return aconf end
end

function add_tit_point( self, idx )
    local conf = self:check_tit_point( idx )
    if not conf then return end
    self:set_tit_point( idx, gTime )
    self.ache_point = (self.ache_point or 0) + conf.Point
    self:try_upgrade_titles()
    return true
end

function gain_ache( self, idx )
    local conf = self:check_ache( idx )
    if not conf then return end
    self:set_ache( idx, gTime )
    --self.ache_point = (self.ache_point or 0) + conf.Point
    --self:try_upgrade_titles()
    return true
end

func_ache.count = function ( self, id, param )
    return self:get_count( id ) 
end

func_ache.castle_lv = function ( self, id, param )
    return self:get_castle_lv()
end

func_ache.player_lv = function ( self, id, param )
    return self.lv
end

func_ache.count_equip = function ( self, id, param )
    local count = 0
    local ts = self:get_equip() 
    local prop_tab = resmng.prop_equip
    for _, v in pairs( ts or {}) do
        if prop_tab[ v.propid ].Class >= param then 
            count = count + 1
        end
    end
    return count
end

func_ache.count_hero = function ( self, id, param )
    local count = 0
    local ts = self:get_hero()
    for _, v in pairs( ts or {}) do
        count = count + 1
    end
    return count
end

func_ache.count_hero_quality = function ( self, id, param )
    local count = 0
    local ts = self:get_hero() 
    local prop_tab = resmng.prop_hero_basic
    for _, v in pairs( ts or {}) do
        if prop_tab[ v.propid ].Quality >= param then count = count + 1 end
    end
    return count
end

func_ache.count_hero_lv = function ( self, id, param )
    local count = 0
    local ts = self:get_hero() 
    for _, v in pairs( ts or {}) do
        if v.lv >= param then count = count + 1 end
    end
    return count
end

func_ache.count_hero_skill = function ( self, id, param )
    local count = 0
    local ts = self:get_hero() 
    for _, v in pairs( ts or {}) do
        local num = 0
        for _, skill in pairs( v.basic_skill or {}) do
            if skill[1] > 0 then num = num + 1 end
        end
        if num >= param then count = count + 1 end
    end
    return count
end

func_ache.count_hero_star = function ( self, id, param )
    local count = 0
    local ts = self:get_hero() 
    local tab = resmng.prop_hero_star_up
    for _, v in pairs( ts or {}) do
        local node = tab[ v.star ]
        if node then
            if node.StarStatus[ 1 ] >= param then count = count + 1 end
        end
    end
    return count
end

