
module( "build_t", package.seeall )
module_class("build_t", {
    _id = "0_0",
    idx = 0,
    pid = 0,
    x = 0, y = 0,
    propid = 0,
    action = 0,
    state = 0,
    tmSn = 0,
    tmStart = 0,
    tmOver = 0,
    extra = {},
    bufs = {},
    hero_idx = 0,
    module_name = "build_t"
})

function create(idx, pid, propid, x, y, state, tmStart, tmOver)
    local _id = string.format("%d_%d", idx, pid)
    local t = {_id=_id, map=gMapID, idx=idx, pid=pid, propid=propid, x=x, y=y, state=state or 2, tmStart=tmStart or 0, tmOver=tmOver or 0, extra={}, bufs={}, hero_idx=0 }
    return new(t)
end

function getData(self)
    return  rawget(self._pro)
end

function on_check_pending(db, _id, chgs)
    local idx, pid = string.match(_id, "(%d+)_(%d+)")
    local p = getPlayer(tonumber(pid))
    if p then
        chgs.idx = tonumber(idx)
        Rpc:stateBuild(p, chgs)
    end
end

function is_hospital( self )
    local idx_min = BUILD_FUNCTION_MODE.HOSPITAL * 100
    local idx_max = (BUILD_FUNCTION_MODE.HOSPITAL + 1) * 100

    local idx = self.idx
    return idx > idx_min and idx < idx_max
end


function is_res( self )
    local prop = resmng.get_conf( "prop_build", self.propid )
    return  prop and prop.Class == BUILD_CLASS.RESOURCE 
end

function is_academy( self )
    local prop = resmng.get_conf( "prop_build", self.propid )
    return  prop and prop.Class == BUILD_CLASS.FUNCTION and prop.Mode == BUILD_FUNCTION_MODE.ACADEMY 
end

function is_forge( self )
    local prop = resmng.get_conf( "prop_build", self.propid )
    return  prop and prop.Class == BUILD_CLASS.FUNCTION and prop.Mode == BUILD_FUNCTION_MODE.FORGE 
end

--------------------------------------------------------------------------------
-- Function : 建筑加速
-- Argument : self, secs
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function acceleration(self, secs)
    if not secs or secs <= 0 then
        INFO("acceleration: secs = %d.", secs or -1)
        return
    end

    if self.state == BUILD_STATE.WAIT then
        ERROR("acceleration: build._id = %s, build.state = BUILD_STATE.WAIT.", self._id)
        return

    else
        if self:is_hospital() and self.state == BUILD_STATE.WORK then
            local start = self.tmStart
            local over = self.tmOver - secs
            local owner = getPlayer( self.pid )
            if owner then 
                player_t.cure_on( owner, start, over) 
                owner.cure_start = start
                owner.cure_over = over
                if owner.tm_cure > 0 then timer.acc( owner.tm_cure, secs ) end
            end

        else
            if self.tmOver > gTime then 
                self.tmStart = self.tmStart - secs 
                self.tmOver = self.tmOver - secs 
            end
            if self.tmSn > 0 then timer.acc(self.tmSn, secs) end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 计算加速所需的金币数量
-- Argument : self
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_gold_for_acc(self)
    if self.state == BUILD_STATE.WAIT then
        ERROR("calc_gold_for_acc: build._id = %s, build.state = BUILD_STATE.WAIT, can't acceleration.", self._id)
        return math.huge
    end

    -- TODO: 找策划要计算公式（剩余CD时间和金币的换算关系），这里暂时扣除10金币做测试用
    -- return self.tmOver - gTime
    return 10
end


--------------------------------------------------------------------------------
-- Function : 校验是否能够使用免费加速
-- Argument : self
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function can_acc_for_free(self)
    -- TODO: check conditions.
    -- 校验Vip等级对应的免费时长与剩余时长
    return true
end


--------------------------------------------------------------------------------
-- Function : cond check
-- Argument : self
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function cond_check(self, check_type, value_1, value_2, value_3)
    if check_type == "BSTATE" then
        return self:state_check(value_1)
    elseif check_type == "BTYPE" then
        return self:type_check(value_1, value_2, value_3)
    end
end


--------------------------------------------------------------------------------
-- Function : state check.
-- Argument : self, state
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function state_check(self, state)
    if self.state == state then
        return true
    else
        return false
    end
end


--------------------------------------------------------------------------------
-- Function : type check.
-- Argument : self, class, mode, lv
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function type_check(self, class, mode, lv)
    local conf = resmng.get_conf("prop_build", self.propid)
    if not conf then
        return false
    end

    if class and class ~= conf.Class then
        return false
    end
    if mode and mode ~= conf.Mode then
        return false
    end

    if lv and lv ~= conf.Lv then
        return false
    end

    return true
end


--------------------------------------------------------------------------------
-- Function : 初始化
-- Argument : NULL
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
--function init(self)
--    local conf = resmng.get_conf("prop_build", self.propid)
--    if not conf then
--        ERROR("build_t.init: get conf failed. propid = %d.", self.propid)
--        return
--    end
--
--    if not self.extra then
--        self.extra = {}
--    end
--
--    -- 监狱
--    if conf.Class == BUILD_CLASS.FUNCTION and conf.Mode == BUILD_FUNCTION_MODE.PRISON then
--        if not self.extra.prisoners_info then
--            self.extra.prisoners_info = {}
--        end
--    end
--end


--------------------------------------------------------------------------------
-- Function : 更新extra
-- Argument : self, chg = {k1 = v1, k2 = v2, ...}
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function update_extra(self, chg)
    if not chg then
        ERROR("update_extra: no chg.")
        return
    end

    local extra = self.extra or {}
    for k, v in pairs(chg) do
        extra[k] = v
    end
    self.extra = extra
end

function set_extra(self, key, val)
    self.extra[ key ] = val
    self.extra = self.extra
end

function set_extras(self, chgs)
    for key, val in pairs(chgs) do
        self.extra[ key ] = val
    end
    self.extra = self.extra
end

function clr_extra(self, key, val)
    self.extra[ key ] = nil
    self.extra = self.extra
end

function clr_extras(self, chgs)
    for _, key in pairs(chgs) do
        self.extra[ key ] = nil
    end
    self.extra = self.extra
end

function get_extra(self, key)
    return self.extra[ key ] 
end


--------------------------------------------------------------------------------
-- Function : 清理extra
-- Argument : self, chg = {key1, key2, ...}
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function get_extra_val(self, what)
    return self.extra and self.extra[ what ]
end

function ef_add(self, eff)
    local t = self.extra.ef
    if not t then
        t = {}
        self.extra.ef = t
    end

    for k, v in pairs(eff) do
        t[ k ] = (t[ k ] or 0) + v
    end
end

function ef_rem(self, eff)
    local t = self.extra.ef
    if not t then
        t = {}
        self.extra.ef = t
    end

    for k, v in pairs(eff) do
        t[ k ] = (t[ k ] or 0) - v
    end
end

function ef_get(self)
    return self.extra.ef or {}
end

function res_reap_some(self, need)
    if self.state == BUILD_STATE.WORK then
        if gTime - self.tmStart > 10 then
            local speed = self:get_extra("speed") or 0
            local cache = self:get_extra("cache") or 0
            local start = self:get_extra("start") or gTime
            local count = self:get_extra("count") or 0

            cache = math.floor(cache + speed * (gTime - start) / 3600)
            if cache > count then cache = count end

            self:set_extra("start", gTime)
            if cache >= need then
                cache = cache - need
                self:set_extra("cache", cache)
                return need
            else
                self:set_extra("cache", 0)
                return cache
            end
        end
    end
    return 0
end

function do_add_buf(self, bufid, dura)
    if not dura or dura == 0 then
        table.insert(self.bufs, {bufid,0})
        self.bufs = self.bufs
    else
        local tmOver = gTime + dura
        table.insert(self.bufs, {bufid, tmOver})
        timer.new("rem_buf_build", dura, self.pid, self.idx, bufid, tmOver)
        self.bufs = self.bufs
    end
end

function add_buf(self, bufid, dura)
    self:do_add_buf(bufid, dura)
    if self.state == BUILD_STATE.WORK then
        self:recalc()
    end
end

function do_rem_buf(self, bufid, over)
    over = over or 0
    for k, v in pairs(self.bufs) do
        if v[1] == bufid and v[2] == over then
            table.remove(self.bufs, k)
            self.bufs = self.bufs
            return true
        end
    end
end

function rem_buf(self, bufid, over)
    if self:do_rem_buf(bufid, over) then
        if self.state == BUILD_STATE.WORK then
            print("rem_buf")
            self:recalc()
        end
    end
end

function init_speed(self)
    self.extra = {}
    self:recalc()
end

function get_ef(self)
    local ef = {}
    for _, buf in pairs(self.bufs) do
        local id = buf[1]
        local over = buf[2]
        if over == 0 or over > gTime then
            local prop = resmng.get_conf("prop_buff", id)
            if prop then
                for k, v in pairs(prop.Value) do
                    ef[ k ] = (ef[ k ] or 0) + v
                end
            end
        end
    end
    return ef
end

function recalc(self)
    if self.state ~= BUILD_STATE.WORK then return end

    local ef = self:get_ef()
    local prop = resmng.get_conf("prop_build", self.propid)
    local class = prop.Class
    local mode = prop.Mode
    local role = getPlayer(self.pid)

    if class == BUILD_CLASS.RESOURCE then
        local speed = self:get_extra("speed") or 0
        local new_speed = math.floor( prop.Speed * ( 1 + ( role:get_num("SpeedRes_R", ef) + role:get_num(string.format("SpeedRes%d_R", prop.Mode), ef) ) * 0.0001 ) )
        if speed == new_speed then return end

        local cache = self:get_extra("cache") or 0
        local start = self:get_extra("start") or gTime
        local count = self:get_extra("count") or 0

        cache = math.floor(cache + speed * (gTime - start) / 3600)
        if cache > count then cache = count end

        speed = new_speed
        count = math.ceil( speed * 10 )

        self:set_extra("speed", speed)
        self:set_extra("cache", cache)
        self:set_extra("start", gTime)
        self:set_extra("count", count)
        self:set_extra("speedb", prop.Speed)
        self:set_extra("countb", prop.Count)
        print("recalc, speed, cache, start, count = ", speed, cache, start, count)

    elseif class == BUILD_CLASS.ARMY then
        local speed = self:get_extra("speed") or 0
        local speedb, speedm, speeda = get_nums_by("SpeedTrain", role._ef, ef)
        local new_speed = 1 * (1 + speedm * 0.0001) + speeda
        if math.floor( speed * 100 ) == math.floor( new_speed * 100 ) then return end

        local cache = self:get_extra("cache") or 0
        local start = self:get_extra("start") or gTime
        print("train1,", speed, cache, start, gTime )

        local make = (gTime - start) * speed
        cache = cache + make

        speed = new_speed 
        self:set_extra("speed", speed)
        self:set_extra("cache", cache)
        self:set_extra("start", gTime)

        local count = self:get_extra("count")
        local need = count - cache 
        if need < 0 then need = 0 end
        need = math.ceil(need / speed)

        print("train,", count, need, speed )
        print("build_arm, recalc, old, new, speed = ", self.tmOver - gTime, need, speed)

        self.tmOver = gTime + need

    elseif class == BUILD_CLASS.FUNCTION then
        if mode == BUILD_FUNCTION_MODE.ACADEMY then
            local speed = self:get_extra("speed") or 0
            local new_speed = 1 + role:get_num( "SpeedTech_R", ef ) * 0.0001
            if speed == new_speed then return end

            local cache = self:get_extra("cache") or 0
            local start = self:get_extra("start") or gTime

            local make = ( gTime - start ) * speed
            cache = cache + make

            speed = new_speed 
            self:set_extra("speed", speed)
            self:set_extra("cache", cache)
            self:set_extra("start", gTime)

            local count = self:get_extra("count")
            local tech_id = self:get_extra("id")
            local need = count - cache 
            if need < 0 then need = 0 end
            need = math.ceil(need / speed)

            self.tmOver = gTime + need
            self.tmSn = timer.new( "build", need, self.pid, self.idx,tech_id )

        end
    end
end

------- for prison
------- for prison
--
function imprison(self, hero, dura)
    local id = hero._id
    local info = self:get_extra("prisoners_info")
    if not info then info = {} end
    dura = dura or 10
    if dura < 1 then dura = 1 end

    local over = gTime + dura
    hero.status = HERO_STATUS_TYPE.BEING_IMPRISONED
    hero.tmStart = gTime
    hero.tmOver = over
    table.insert(info, { id=hero._id, start=gTime, over=over} )
    timer.new("expiry", dura, self.pid, hero._id, over)
    self:set_extra("prisoners_info", info)
end

function release(self, id, over)
    local info = self:get_extra("prisoners_info")
    for k, v in pairs(info or {}) do
        if v.id == id then
            if (not over) or (v.over == over) then 
                table.remove(info, k)
                self:set_extra("prisoners_info", info)
                return heromng.get_hero_by_uniq_id(id)
            end
            return
        end
    end
end

function pullone(self)
    local info = self:get_extra("prisoners_info")
    if info then
        local t = table.remove(info,1)
        if t then 
            self:set_extra("prisoners_info", info)
            return heromng.get_hero_by_uniq_id(t.id)
        end
    end
end

function get_param(self, key)
    local conf = self.prop
    if conf and conf.ID == self.propid then
        return conf.Param[ key ]
    end

    local conf = resmng.get_conf("prop_build", self.propid)
    if conf then
        self.prop = conf
        return conf.Param[ key ]
    end
end

