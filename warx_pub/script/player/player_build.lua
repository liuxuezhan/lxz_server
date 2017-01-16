--------------------------------------------------------------------------------
-- Desc     : player build
-- Author   : Yang Cong
-- History  :
--     2016-1-26 11:52:14 Created
-- Copyright: Chengdu Tapenjoy Tech Co.,Ltd
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
module("player_t")

local g_black_market_day
local g_black_market_day_hot

--------------------------------------------------------------------------------
-- load
function do_load_build(self)
    local db = self:getDb()
    local info = db.build_t:find({pid=self.pid})
    local bs = {}
    while info:hasNext() do
        local b = info:next()
        bs[ b.idx ] = build_t.wrap(b)
    end
    return bs
end


--------------------------------------------------------------------------------
-- Function : 计算建筑在 ply._build 中的 idx
-- Argument : self, build_class, build_mode, build_seq 玩家拥有的第几个该类型建筑
-- Return   : succ - build_idx; fail - nil
-- Others   : 传入 build_seq 时表示根据 build_class, build_mode, build_seq 计算 build_idx;
--            不传入 build_seq 时表示根据 build_class, build_mode 获取一个可用的 build_idx
--------------------------------------------------------------------------------
function calc_build_idx(self, build_class, build_mode, build_seq)
    return build_class * 10000 + build_mode * 100 + (build_seq or 1)
end

function get_new_idx(self, build_class, build_mode)
    local max_seq = (BUILD_MAX_NUM[build_class] and BUILD_MAX_NUM[build_class][build_mode]) or 1
    local idx = self:calc_build_idx(build_class, build_mode, 1)
    if max_seq == 1 then
        if self:get_build(idx) then
            return nil
        else
            return idx
        end
    else
        for i = 1, max_seq, 1 do
            if not self:get_build(idx) then
                return idx
            else
                idx = idx + 1
            end
        end
    end
end


-- get
function get_build(self, idx)
    if not self._build then self._build = self:do_load_build() end
    if idx then
        if self._build then return self._build[ idx ] end
    else
        return self._build
    end
end

function check_is_building( self, idx )
    if idx then
        local build = self:get_build( idx )
        if build then
            if build.tmSn > 0 then
                local tm = timer.get( build.tmSn ) 
                if tm then
                    if tm.over >= gTime then return true end
                end
            end
        end
    end
end

function check_build_queue( self, dura )
    local queues = self.build_queue
    if queues[ 1 ] == 0 then return true end

    if not self:check_is_building( queues[ 1 ] ) then
        queues[ 1 ] = 0
        return true
    end

    local remain = self:get_buf_remain( resmng.BUFF_COUNT_BUILD )
    if remain > 0 then
        queues[ 2 ] = queues[ 2 ] or 0
        if queues[ 2 ] == 0 then return remain >= dura end

        if not self:check_is_building( queues[ 2 ] ) then
            queues[ 2 ] = 0
            return remain >= dura
        end
    end

    return false
end

function mark_build_queue( self, idx )
    local queues = self.build_queue
    if queues[ 1 ] == 0 then
        queues[ 1 ] = idx
        self.build_queue = queues
        return true
    end
    local remain = self:get_buf_remain( resmng.BUFF_COUNT_BUILD )
    if remain > 0 then
        queues[ 2 ] = idx
        self.build_queue = queues
        return true
    end
    return false
end

function clear_build_queue( self, idx )
    local queues = self.build_queue
    if queues[ 1 ] == idx then
        queues[ 1 ] = 0
        self.build_queue = queues
        return true
    end

    if queues[ 2 ] == idx then
        queues[ 2 ] = 0
        self.build_queue = queues
        return true
    end
end

--------------------------------------------------------------------------------
-- Function : 根据 class, mode, seq 获取建筑
-- Argument : self, build_class, build_mode, build_seq
-- Return   : succ - build; fail - nil
-- Others   : build_seq 默认值为 1
--------------------------------------------------------------------------------
function get_build_extra(self, build_class, build_mode, build_seq)
    local max_seq = BUILD_MAX_NUM[build_class] and BUILD_MAX_NUM[build_class][build_mode]
    if not max_seq then
        ERROR("get_build_extra: get max_seq failed. pid = %d, build_class = %d, build_mode = %d.", self.pid, build_class or -1, build_mode or -1)
        return
    end

    local build_idx = self:calc_build_idx(build_class, build_mode, build_seq or 1)
    if not build_idx then
        return
    end

    local build = self:get_build(build_idx)
    if not build then
        INFO("get_build_extra: get_build() failed. pid = %d, build_idx = %d.", self.pid, build_idx)
        return
    else
        return build
    end
end


--------------------------------------------------------------------------------
-- Function : 根据 class 和 mode 获取玩家身上所有满足条件的建筑
-- Argument : self, build_class, build_mode
-- Return   : succ - {1=build_1, ...}; fail - {}
-- Others   : NULL
--------------------------------------------------------------------------------
function get_builds_extra(self, build_class, build_mode)
    local max_seq = BUILD_MAX_NUM[build_class] and BUILD_MAX_NUM[build_class][build_mode]
    if not max_seq then
        ERROR("get_builds_extra: get max_seq failed. pid = %d, build_class = %d, build_mode = %d.", self.pid, build_class or -1, build_mode or -1)
        return {}
    end

    local ret = {}
    for seq = 1, max_seq do
        local build_idx = self:calc_build_idx(build_class, build_mode, seq)
        local build = self:get_build(build_idx)
        if not build then
            -- 已取到所有此类建筑
            --break
        else
            table.insert(ret, build)
        end
    end

    return ret
end


-- set
function set_build(self, idx, b)
    local bs = self:get_build()
    bs[ idx ] = b
end


-- 建造
function construct(self, x, y, build_propid)
    if not x or not y or not build_propid then
        ERROR("construct: arguments error. x = %d, y = %d, build_propid = %d", x or -1, y or -1, build_propid or -1)
        ack(self, "construct", resmng.E_FAIL)
    end

    local node = resmng.prop_build[ build_propid ]
    if not node.Dura then
        WARN("%d",build_propid)
        return
    end

    if node and node.Lv == 1 then
        if self:condCheck(node.Cond) and self:consCheck(node.Cons) then
            if not self:check_build_queue( node.Dura ) then return end
            local id = string.format("_%d", self.pid)
            local idx = self:get_new_idx(node.Class, node.Mode)
            if idx then
                local max_seq = (BUILD_MAX_NUM[node.Class] and BUILD_MAX_NUM[node.Class][node.Mode]) or 1
                if max_seq > 1 then
                    local field =  math.floor( (x - 100) / 5 ) + 1
                    if field > self.field then return ack( self, "construct", resmng.E_FAIL ) end

                    local bs = self:get_build()
                    for k, v in pairs( bs ) do
                        if v.x == x then
                            return ack( self, "construct", resmng.E_FAIL )
                        end
                    end
                end

                self:consume(node.Cons, 1, VALUE_CHANGE_REASON.BUILD_CONSTRUCT)

                local dura = math.ceil( node.Dura / ( 1 + self:get_num( "SpeedBuild_R" ) * 0.0001 ) )
                local t = build_t.create(idx, self.pid, node.ID, x, y, BUILD_STATE.CREATE, gTime, gTime+dura)
                t.tmSn = timer.new("build", dura, self.pid, idx)
                self:set_build(idx, t)
                Rpc:stateBuild(self, t._pro)
                self:mark_build_queue( idx )

                LOG("construct: pid = %d, build.propid = %d, build.x = %d, build.y = %d", self.pid, build_propid, x, y)
                return
            else
                ERROR("construct: get build_idx failed, pid = %d, node.Class = %d, node.Mode = %d.", self.pid, node.Class, node.Mode)
            end
        end
    end
    ack(self, "construct", resmng.E_FAIL)
end


-- 定时器升级
function upgrade(self, idx)
    local build = self:get_build(idx)
    if build then
        local node = resmng.prop_build[ build.propid ]
        if node then
            local flag = false
            if build.state == BUILD_STATE.WAIT then
                flag = true
            elseif build.state == BUILD_STATE.WORK then
                if node.Class == BUILD_CLASS.RESOURCE then flag = true end
                if build:is_hospital() then flag = true end
            end

            if not flag then
                return ack(self, "upgrade", resmng.E_FAIL)
            end

            local id = node.ID + 1
            local dst = resmng.prop_build[ id ]
            if dst then
                if self:condCheck(dst.Cond) and self:consCheck(dst.Cons) then
                    if not self:check_build_queue( dst.Dura ) then return end

                    if dst.Class == BUILD_CLASS.RESOURCE then self:reap( idx ) end

                    local dura = math.ceil( dst.Dura / ( 1 + self:get_num( "SpeedBuild_R" ) * 0.0001 ) )
                    self:consume(dst.Cons, 1, VALUE_CHANGE_REASON.BUILD_UPGRADE)
                    build.state = BUILD_STATE.UPGRADE
                    build.tmStart = gTime
                    build.tmOver = gTime + dura
                    build.tmSn = timer.new("build", dura, self.pid, idx)

                    self:mark_build_queue( idx )

                    LOG("upgrade: pid = %d, build.propid = %d, build.idx = %d", self.pid, build.propid, idx)
                    return
                end
            end
        end
    end
    ack(self, "upgrade", resmng.E_FAIL)
end


--------------------------------------------------------------------------------
-- Function : 这里才是真的升级
-- Argument : self, build_idx
-- Return   : succ - true; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function do_upgrade(self, build_idx)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("do_upgrade: get_build() failed, pid = %d, build_idx = %d", self.pid, build_idx)
        return false
    end

    local node = resmng.get_conf("prop_build", build.propid)
    if node then
        local id = node.ID + 1
        local dst = resmng.get_conf("prop_build", id)
        if dst then
            self:ef_chg(node.Effect or {}, dst.Effect or {})
            build.propid = dst.ID

            if dst.Class == BUILD_CLASS.RESOURCE then
                build.state = BUILD_STATE.WORK
                build:init_speed()
                --任务
                task_logic_t.process_task(self, TASK_ACTION.RES_OUTPUT)
            end

            if dst.Class == BUILD_CLASS.FUNCTION then
                if dst.Mode == BUILD_FUNCTION_MODE.CASTLE then
                    if self.culture == 0 then self.culture = 1 end
                    local id = CLASS_UNIT.PLAYER_CITY * 1000 * 1000 + self.culture * 1000 + dst.Lv
                    local unit = resmng.get_conf("prop_world_unit", id)
                    if unit then
                        self.propid = id
                        etypipe.add(self)
                    end
                    self.tm_lv_castle = gTime
                    rank_mng.add_data(1, self.pid, {dst.Lv, self.tm_lv_castle})

                    self:try_add_tit_point(resmng.ACH_LEVEL_CASTLE)

                    if dst.Lv >= 6 then self:rem_buf( resmng.BUFF_SHELL_ROOKIE ) end

                    --开启建筑
                    for k, v in pairs(resmng.prop_citybuildview) do
                        if v.OpenCastleLv ~= nil then
                            if dst.Lv >= v.OpenCastleLv then
                                local build_id = v.ID * 1000 + 1
                                local bs = self:get_build()
                                local conf = resmng.get_conf("prop_build", build_id)
                                local idx_new = self:calc_build_idx(conf.Class, conf.Mode, 1)
                                if bs[ idx_new ] == nil then
                                    local build_new = build_t.create(idx_new, self.pid, build_id, 0, 0, BUILD_STATE.CREATE)
                                    bs[ idx_new ] = build_new
                                    if build_id == 21001 then
                                        --self:open_online_award()
                                        build_new.extra.next_time = self:get_online_award_next_time()
                                    end
                                    build_new.tmSn = 0
                                    self:doTimerBuild( 0, idx_new )
                                end
                            end
                        end
                    end

                    --接收每日任务
                    self:take_daily_task()
                    --向登录服务器注册
                    self:upload_user_info()

                elseif dst.Mode == BUILD_FUNCTION_MODE.WALLS then
                    local cur = build:get_extra( "cur" )
                    if cur then
                        local src = resmng.get_conf( "prop_build", dst.ID - 1)
                        local offset = dst.Param.Defence - src.Param.Defence
                        cur = cur + offset
                        if cur > dst.Param.Defence then cur = dst.Param.Defence end
                        build:set_extra( "cur", cur )
                    end
                end
            end

            new_union.update(self)
            if build_idx == 1 then
                self:pre_tlog("PlayerExpFlow",0,node.Lv-1,0,0)
            end
            --任务
            task_logic_t.process_task(self, TASK_ACTION.CITY_BUILD_LEVEL_UP)
            task_logic_t.process_task(self, TASK_ACTION.CITY_BUILD_MUB, 1)
            task_logic_t.process_task(self, TASK_ACTION.PROMOTE_POWER, 1, dst.Pow)

            if dst.Pow then
                self.pow_build = self.pow_build + dst.Pow - ( node.Pow or 0 )
                self:inc_pow(dst.Pow-node.Pow)
            end
            return true
        end
    end

    ERROR("do_upgrade: upgrade failed. pid = %d, build_idx = %d", self.pid, build_idx)
    return false
end


--------------------------------------------------------------------------------
-- Function : 一键升级
-- Argument : self, build_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function one_key_upgrade_build(self, build_idx)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("one_key_upgrade_build: get_build() failed, pid = %d, build_idx = %d.", self.pid, build_idx or -1)
        return
    end

    local node = resmng.get_conf("prop_build", build.propid)
    if not node then return end

    local state = false
    if build.state == BUILD_STATE.WAIT then
        state = true
    elseif build.state == BUILD_STATE.WORK and node.Class == BUILD_CLASS.RESOURCE then
        state = true
    end

    if not state then
        INFO("one_key_upgrade_build: build._id = %s, build.state(%d) ~= BUILD_STATE.WAIT", build._id, build.state)
        return
    end

    local dst = resmng.get_conf("prop_build", node.ID + 1)
    if not dst then
        --ERROR("one_key_upgrade_build: get next node failed. build._id = %s, build lv = %d", build._id, node.Lv)
        return
    else
        if not self:condCheck(dst.Cond) then
            --self:add_debug(string.format("one_key_upgrade_build: check cond failed. build._id = %s", build._id))
            return
        else
            -- 优先使用已有资源，不足的扣除相应金币
            -- 校验所需资源，拆分为 cons_have 和 cons_need_buy
            local cons_have, cons_need_buy = self:split_cons(dst.Cons)
            if not cons_have then
                ERROR("one_key_upgrade_build: split_cons() failed.")
                dumpTab(dst.Cons, string.format("prop_build[%d]", node.ID + 1))
                return
            end

            local dura = dst.Dura - self:get_val( "BuildFreeTime" )
            if dura < 0 then dura = 0 end

            local gold_need = calc_cons_value(cons_need_buy) + calc_acc_gold(dura)
            if gold_need > 0 and gold_need > self.gold then
                INFO("one_key_upgrade_build: pid = %d, player.gold(%d) < gold_need(%d)", self.pid, self.gold, gold_need)
                return
            else
                -- 扣除 cons_have 和 gold_need
                self:dec_cons(cons_have, VALUE_CHANGE_REASON.BUILD_UPGRADE, true)
                if gold_need > 0 then
                    self:do_dec_res(resmng.DEF_RES_GOLD, gold_need, VALUE_CHANGE_REASON.BUILD_UPGRADE)
                end

                if dst.Class == BUILD_CLASS.RESOURCE then self:reap( build_idx ) end

                -- 升级
                self:do_upgrade(build_idx)
            end
        end
    end
end


-- timer function
function doTimerBuild(self, tsn, build_idx, arg_1, arg_2, arg_3, arg_4)
    local build = self:get_build(build_idx)
    if build then
        if build.tmSn ~= tsn then return end
        local state = build.state
        build.state = BUILD_STATE.WAIT
        build.tmSn = 0
        build.tmStart = gTime
        build.tmOver = 0

        if state == BUILD_STATE.CREATE then
            local node = resmng.prop_build[ build.propid ]
            if node then
                self:clear_build_queue( build.idx )
                self:inc_pow(node.Pow or 0)
                if node.Effect then self:ef_add(node.Effect) end
                if node.Class == BUILD_CLASS.RESOURCE then
                    build.state = BUILD_STATE.WORK
                    build:init_speed()
                    --任务
                    task_logic_t.process_task(self, TASK_ACTION.RES_OUTPUT)
                end
                task_logic_t.process_task(self, TASK_ACTION.CITY_BUILD_LEVEL_UP)

                if build.propid == resmng.BUILD_BLACKMARKET_1 then self:refresh_black_marcket() end
                if build.propid == resmng.BUILD_MANOR_1 or build.propid == resmng.BUILD_MONSTER_1 or build.propid == resmng.BUILD_RELIC_1 then self:refresh_mall() end
                if build.propid == resmng.BUILD_RESOURCESMARKET_1 then self:refresh_res_market() end

                if node.Pow then
                    self.pow_build = (self.pow_build or 0) + node.Pow
                    self:inc_pow( node.Pow )
                end
            end
        elseif state == BUILD_STATE.UPGRADE then
            self:clear_build_queue( build.idx )
            self:do_upgrade(build_idx)


        elseif state == BUILD_STATE.DESTROY then
            local conf = resmng.get_conf("prop_build", build.propid)
            if conf then
                if conf.Effect then self:ef_rem( conf.Effect ) end
                if conf.Pow then self:dec_pow( conf.Pow ) end
            end
            self:clear_build_queue( build_idx )
            self._build[ build_idx ] = nil
            Rpc:stateBuild( self, { idx=build.idx, delete=true } )
            build:clr()

        elseif state == BUILD_STATE.WORK then
            local conf = resmng.get_conf("prop_build", build.propid)
            if not conf then
                ERROR("doTimerBuild: get prop_build config failed. pid = %d, build_idx = %d, build.propid = %d", self.pid, build_idx, build.propid)
                return
            end

            -- 根据建筑类型，分别调用对应的接口
            if conf.Class == BUILD_CLASS.FUNCTION then
                if conf.Mode == BUILD_FUNCTION_MODE.ACADEMY then
                    -- 研究院
                    local id = build:get_extra( "id" )
                    build.extra = {}
                    self:do_learn_tech(build, id)
                    self:add_count( resmng.ACH_COUNT_RESEARCH, 1 )

                elseif conf.Mode == BUILD_FUNCTION_MODE.HOSPITAL then
                    -- 医疗所(治疗)
                    -- "CureSpeed"

                elseif conf.Mode == BUILD_FUNCTION_MODE.ALTAR then
                    -- 祭坛
                    --self:real_kill_hero(arg_1, arg_2, arg_3)
                    --altar.tmSn    = timer.new("build", kill_time, self.pid, altar.idx, tmOver, buff_id, buff_time)
                    local tmOver, buff_id, buff_time = arg_1, arg_2, arg_3
                    local info = build.extra.kill
                    if info and info.over == tmOver then
                        build:clr_extra("kill")
                        local hero = heromng.get_hero_by_uniq_id(info.id)
                        if hero then
                            hero.status = HERO_STATUS_TYPE.DEAD
                            self:add_count( resmng.ACH_COUNT_KILL_HERO, 1 )

                            local buff = build:get_extra("buff")
                            if buff and buff.over > gTime then
                                self:rem_buf(buff.id, buff.over)
                            end

                            local newbuf = self:add_buf(buff_id, buff_time)
                            build:set_extra("buff", {id=buff_id, start=gTime, over=newbuf[3]})
                        end
                    end

                elseif conf.Mode == BUILD_FUNCTION_MODE.FORGE then
                    local tid = build:get_extra_val("forge")
                    if tid then
                        self:equip_add(tid, VALUE_CHANGE_REASON.FORGE)
                    end
                    build:clr_extra("forge")
                    build:clr_extra("silver")

                end

            elseif conf.Class == BUILD_CLASS.RESOURCE then

            elseif conf.Class == BUILD_CLASS.ARMY then
                local extra = build.extra
                if extra and extra.id and extra.id > 0 and extra.num > 0 then
                    self:add_soldier( extra.id, extra.num )
                    self:add_count( resmng.ACH_COUNT_TRAIN, extra.num )

                    --成就
                    local conf = resmng.get_conf( "prop_arm", extra.id )
                    local ach_index = "ACH_TASK_RECRUIT_SOLDIER"..( conf.Mode * 1000 + conf.Lv )
                    self:add_count(resmng[ach_index], extra.num)

                    --任务
                    task_logic_t.process_task(self, TASK_ACTION.RECRUIT_SOLDIER, conf.Mode, conf.Lv, extra.num)
                    task_logic_t.process_task(self, TASK_ACTION.GET_RES, conf.Mode)

                    build.extra = {}
                end
            end
        end
    end
end

function is_building( self, build )
    local state = build.state
    return state == BUILD_STATE.DESTROY or state == BUILD_STATE.CREATE or state == BUILD_STATE.UPGRADE or state == BUILD_STATE.FIX
end

--------------------------------------------------------------------------------
-- Function : 使用金币或者免费时间加速建筑
-- Argument : self, build_idx, acc_type
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function acc_build(self, build_idx, acc_type)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("acc_build: pid = %d, build_idx = %d", self.pid, build_idx or -1)
        return
    end
    --判断生产资源的建筑在生产状态不能加速
    local prop_tab = resmng.prop_build[build.propid]
    if prop_tab == nil then return end

    if prop_tab.Class == 1 and build.state == BUILD_STATE.WORK then return end
    
    local state = build.state
    --if state == BUILD_STATE.FREE or state == BUILD_STATE.WORK then
    if state == BUILD_STATE.FREE then
        INFO("acc_build: pid = %d, build_idx = %d, build.state = %d", self.pid, build_idx, build.state)
        return
    end

    local tm = timer.get( build.tmSn )
    if not tm then return end

    if acc_type == ACC_TYPE.FREE then
        if self:is_building( build ) then
            local remain = build.tmOver - gTime
            build:acceleration( remain )
        end

    elseif acc_type == ACC_TYPE.GOLD then
        local dura = build.tmOver - gTime
        if self:is_building( build ) then
            local quick = self:get_val( "BuildFreeTime" )
            dura = dura - quick
        end

        if dura < 0 then dura = 0 end
        local num = calc_acc_gold( dura )
        if num > 0 then
            if self:get_res_num(resmng.DEF_RES_GOLD) < num  then return end
            self:do_dec_res(resmng.DEF_RES_GOLD, num, VALUE_CHANGE_REASON.BUILD_ACC)
            task_logic_t.process_task(self, TASK_ACTION.GOLD_ACC, 1)
        end
    else
        ERROR("acc_build: pid = %d, build_idx = %d, acc_type = %d", self.pid, build_idx, acc_type or -1)
        return
    end

    build.tmOver = gTime
    timer.adjust( tm._id, gTime )

    return true
end


--------------------------------------------------------------------------------
-- Function : Use speed item.
-- Argument : self, build_idx, item_idx, num
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function item_acc_build(self, build_idx, item_idx, num)
    -- check arguments.
    if not build_idx or not item_idx or not num or num <= 0 then
        ERROR("item_acc_build: pid = %d, build_idx = %d, item_idx = %d, num = %d", self.pid or -1, build_idx or -1, item_idx or -1, num or -1)
        return
    end

    -- check item.
    local item = self:get_item(item_idx)
    if not item then
        ERROR("item_acc_build: get_item() failed. pid = %d, item_idx = %d", self.pid or -1, item_idx)
        return
    end

    local conf = resmng.get_conf("prop_item" ,item[2])
    if not conf or conf.Class ~= ITEM_CLASS.SPEED then
        ERROR("item_acc_build: not speed item. pid = %d, item_idx = %d, item_id = %d, item_class = %d",
               self.pid or -1, item_idx, item[2], conf and conf.Class or -1)
        return
    end

    -- check build state.
    local build = self:get_build(build_idx)
    if not build then
        ERROR("item_acc_build: get_build() failed. pid = %d, build_idx = %d", self.pid, build_idx)
        return
    end

    if build.state == BUILD_STATE.WAIT then
        ERROR("item_acc_build: pid = %d, build_idx = %d, build.state = BUILD_STATE.WAIT", self.pid, build_idx)
        return
    end

    if not self:build_cond_check(build, conf.Cond) then
        ERROR("item_acc_build: build_cond_check not pass. pid = %d, build_idx = %d, build.state= %d, item_idx= %d, item_id= %d",
               self.pid, build_idx, build.state, item_idx, item[2])
        dumpTab(conf.Cond, "conf.Cond")
        return
    end
    
    -- speed up.
    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.BUILD_ACC) then
        build:acceleration(conf.Param * num)
    end
    return conf.Param * num
end


--------------------------------------------------------------------------------
-- Function : check cond.
-- Argument : self, build, tab
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function build_cond_check(self, build, tab)
    if not build then
        ERROR("build_cond_check: no build.")
        return false
    end

    if tab then
        if not do_build_cond_check(build, unpack(tab)) then
            return false
        end
    end

    return true
end

-- do cond check
function do_build_cond_check(build, value_1, value_2, value_3, ...)
    if value_1 == "AND" then
        for _, v in pairs({value_2, value_3, ...}) do
            if not build:cond_check(unpack(v)) then return false end
        end
        return true
    elseif value_1 == "OR" then
        for _, v in pairs({value_2, value_3, ...}) do
            if build:cond_check(unpack(v)) then return true end
        end
        return false
    end

    return false
end

function get_res_remain( self, n )
    if n.state ~= BUILD_STATE.WORK then return 0 end
    local prop = resmng.get_conf("prop_build", n.propid)
    if not prop then return 0 end
    if prop.Class ~= BUILD_CLASS.RESOURCE then return 0 end

    local mode = prop.Mode
    local speed = n:get_extra("speed") or 0
    local cache = n:get_extra("cache") or 0
    local start = n:get_extra("start") or gTime
    local count = n:get_extra("count") or 0

    if speed == 0 then
        --n:init_speed()
        return 0
    end

    if cache > count then

    else
        cache = math.floor(cache + speed * (gTime - start) / 3600)
        if cache > count then cache = count end
    end
    return cache
end

-- 收获
function reap(self, idx)
    local n = self:get_build(idx)
    if n then
        if n.state ~= BUILD_STATE.WORK then return end
        if gTime - n.tmStart < 60 then
            --WARN(n.tmStart..":时间没到gTime:"..gTime)
            return
        end

        local prop = resmng.get_conf("prop_build", n.propid)
        if not prop then return end
        if prop.Class ~= BUILD_CLASS.RESOURCE then return end


        local mode = prop.Mode
        local speed = n:get_extra("speed") or 0
        local cache = n:get_extra("cache") or 0
        local start = n:get_extra("start") or gTime
        local count = n:get_extra("count") or 0

        n:set_extra("cache", 0)
        n:set_extra("start", gTime)
        n:set_extra("count", math.ceil( speed * 10 ))

        if speed == 0 then
            n:init_speed()
            return
        end

        if cache > count then

        else
            cache = math.floor(cache + speed * (gTime - start) / 3600)
            if cache > count then cache = count end
        end

        self:do_inc_res_normal(prop.Mode, cache, VALUE_CHANGE_REASON.REAP)
        --任务
        task_logic_t.process_task(self, TASK_ACTION.GET_RES, (prop.Mode+4)) -- +4是为了让类型和表里面的对上，mode实际是1234，任务表里面是5678
        n.tmStart = gTime
    end
end

function equip_forge(self, id)
    local b = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.FORGE)
    if not b or b.state ~= BUILD_STATE.WAIT then return LOG("forge, pid=%d, state=%d", self.pid, b and b.state or -1) end

    local n = resmng.get_conf("prop_equip", id)
    if not n then return end

    local silver = math.ceil( n.Silver * ( 1 + self:get_num( "SilverCoinConsume_R" ) * 0.0001 ) )
    if self.silver < silver then return end
    if not self:condCheck(n.Cons) then return LOG("forge, pid=%d, state=%d", self.pid, b and b.state or -1) end

    self:consume(n.Cons, 1, VALUE_CHANGE_REASON.FORGE)
    self:consume({{1, 8, silver}}, 1, VALUE_CHANGE_REASON.FORGE)
    
    b.state = BUILD_STATE.WORK
    b.tmStart = gTime
    b.extra = { count = n.Dura, forge = id, silver = silver }
    b:recalc()
end


function equip_split(self, id)
    print("equip_split", id)
    local n = self:get_equip(id)
    if not n then return LOG("equip_split, no equip") end
    if n.pos ~= 0 then return end -- equip_on

    local prop = resmng.get_conf("prop_equip", n.propid)
    if not prop then return LOG("equip_split, no prop") end

    self:obtain(prop.Split, 1, VALUE_CHANGE_REASON.SPLIT)
    self:equip_rem(id, VALUE_CHANGE_REASON.SPLIT)
end


-- 训练
function train(self, idx, armid, num, quick)
    -- check params
    local build = self:get_build(idx)
    if not build then return end

    if build.state ~= BUILD_STATE.WAIT then return end
    local bnode = resmng.prop_build[ build.propid ]
    if not bnode then return end
    if bnode.Class ~= 2 then return self:add_debug("class~=2") end

    local anode = resmng.prop_arm[ armid ]
    if not anode then return self:add_debug("no armid") end
    if anode.Mode ~= bnode.Mode then return self:add_debug("mode") end
    if anode.Class ~= self.culture then return self:add_debug("class") end

    if anode.Lv > bnode.TrainLv then return self:add_debug("lv") end

    local maxTrain = self:get_val("CountTrain")
    if num > maxTrain then return self:add_debug("CountTrain") end

    if not self:condCheck(anode.Cond) then return false end

    local dura = num * anode.TrainTime
    if quick == 0 then
        if not self:consCheck(anode.Cons, num) then return false end
        self:consume(anode.Cons, num, VALUE_CHANGE_REASON.TRAIN)

        build.state = BUILD_STATE.WORK
        build.tmStart = gTime
        build.extra = { count = dura }
        build:set_extras({id=armid, num=num})
        build:recalc()

        build.tmSn = timer.new( "build", build.tmOver-gTime, self.pid, idx )
        reply_ok( self, "train", 0 )

    elseif quick == 1 then
        local cons = {}
        for k, v in pairs( anode.Cons ) do
            table.insert( cons, { v[1], v[2], v[3] * num } )
        end

        if self:do_consume_quick( cons, dura, VALUE_CHANGE_REASON.TRAIN ) then
            self:add_soldier( armid, num )

            self:add_count( resmng.ACH_COUNT_TRAIN, num )

            reply_ok( self, "train", 0 )

            --成就

            local ach_index = "ACH_TASK_RECRUIT_SOLDIER".. ( armid %  1000000 )
            self:add_count(resmng[ach_index], num)

            --任务
            local soldier_type = anode.Mode
            local soldier_level = anode.Lv
            task_logic_t.process_task(self, TASK_ACTION.RECRUIT_SOLDIER, soldier_type, soldier_level, num)
        end
    end
end



-- 征募
function draft(self, idx)
    local build = self:get_build(idx)
    if not build then return end
    
    if build.state ~= BUILD_STATE.WAIT then return INFO("draft, not state %s", build.state) end

    local extra = build.extra
    if extra and extra.id and extra.id > 0 and extra.num > 0 then
        self:add_soldier( extra.id, extra.num )
        self:add_count( resmng.ACH_COUNT_TRAIN, extra.num )

        --成就
        local conf = resmng.get_conf( "prop_arm", extra.id )
        local ach_index = "ACH_TASK_RECRUIT_SOLDIER"..( conf.Mode * 1000 + conf.Lv )
        self:add_count(resmng[ach_index], extra.num)

        --任务
        task_logic_t.process_task(self, TASK_ACTION.RECRUIT_SOLDIER, conf.Mode, conf.Lv, extra.num)
        task_logic_t.process_task(self, TASK_ACTION.GET_RES, conf.Mode)

        build.extra = {}
    end
    --Rpc:stateBuild(self, build._pro)
end


function do_tech_check(self, build_idx, tech_id)
    local build = self:get_build(build_idx)
    if not build or build.state ~= BUILD_STATE.WAIT then
        ERROR("learn_tech: pid = %d, build_idx = %d, build.state(%d) ~= BUILD_STATE.WAIT", self.pid, build_idx or -1, build and build.state or -1)
        return
    end

    local build_conf = resmng.get_conf("prop_build", build.propid)
    if not build_conf then
        return
    else
        if build_conf.Class ~= BUILD_CLASS.FUNCTION or build_conf.Mode ~= BUILD_FUNCTION_MODE.ACADEMY then
            ERROR("learn_tech: not academy. pid = %d, build_idx = %d, build.propid = %d, build_conf.Class = %d, build_conf.Mode = %d",
                   self.pid, build_idx, build.propid, build_conf.Class, build_conf.Mode)
            return
        end
    end

    local tech_conf = resmng.get_conf("prop_tech", tech_id)
    if not tech_conf then
        ERROR("learn_tech: get prop tech config failed. pid = %d, tech_id = %d", self.pid, tech_id or -1)
        return
    end

    -- check repeat.
    for k, v in pairs(self.tech) do
        local t = resmng.get_conf("prop_tech", v)
        if not t then
            ERROR("learn_tech: get prop_tech config failed. pid = %d, v = %d", self.pid, v)
            return
        end

        if t.Class == tech_conf.Class and t.Mode == tech_conf.Mode and t.Lv >= tech_conf.Lv then
            ERROR("learn_tech: pid = %d, tech_id = %d, already have tech %d.", self.pid, tech_id, v)
            return
        end
    end
    return build
end

function do_consume_quick( self, cons, dura, reason )
    local cons_have, cons_need_buy = self:split_cons(cons)
    if not cons_have then
        ERROR("one_key_upgrade_build: split_cons() failed.")
        return
    end

    --local gold_need = calc_cons_value(cons_need_buy) + self:calc_cd_golds(dst.Dura)
    local gold_need = calc_cons_value(cons_need_buy) + calc_acc_gold(dura)
    if gold_need > 0 and gold_need > self.gold then
        ERROR("one_key_upgrade_build: pid = %d, player.gold(%d) < gold_need(%d)", self.pid, self.gold, gold_need)
        return
    else
        -- 扣除 cons_have 和 gold_need
        self:dec_cons(cons_have, reason, true)
        if gold_need > 0 then
            self:do_dec_res(resmng.DEF_RES_GOLD, gold_need, reason)
        end
        return true
    end
end

-- 研究科技
function learn_tech(self, build_idx, tech_id, is_quick)
    print( "learn_tech", self.pid, build_idx, tech_id, is_quick )

    local build = self:get_build(build_idx)
    
    if not build then return end
    if build.state ~= BUILD_STATE.WAIT then
        if is_quick ~= 1 then return end
    end

    local build_conf = resmng.get_conf("prop_build", build.propid)
    if not build_conf then
        return
    else
        if build_conf.Class ~= BUILD_CLASS.FUNCTION or build_conf.Mode ~= BUILD_FUNCTION_MODE.ACADEMY then
            ERROR("learn_tech: not academy. pid = %d, build_idx = %d, build.propid = %d, build_conf.Class = %d, build_conf.Mode = %d",
                   self.pid, build_idx, build.propid, build_conf.Class, build_conf.Mode)
            return
        end
    end

    local tech_conf = resmng.get_conf("prop_tech", tech_id)
    if not tech_conf then
        ERROR("learn_tech: get prop tech config failed. pid = %d, tech_id = %d", self.pid, tech_id or -1)
        return
    end

    -- check repeat.
    local lv = tech_conf.Lv
    for k, v in pairs(self.tech) do
        local t = resmng.get_conf("prop_tech", v)
        if not t then
            ERROR("learn_tech: get prop_tech config failed. pid = %d, v = %d", self.pid, v)
            return
        end

        if t.Class == tech_conf.Class and t.Mode == tech_conf.Mode then
            if t.Lv >= lv then return end
        end
    end

    if lv > 1 then
        if not is_in_table( self.tech, tech_id - 1 ) then return end
    end

    -- check & consume
    if not self:condCheck(tech_conf.Cond) then
        ERROR("learn_tech: check cond failed. pid = %d", self.pid)
        return
    end

    if is_quick == 1 then
        if build.state == BUILD_STATE.WORK then
            local id = build:get_extra( "id" )
            if id then
                local tconf = resmng.get_conf( "prop_tech", id )
                if tconf then
                    if tconf.Class == tech_conf.Class and tconf.Mode == tech_conf.Mode then
                        return
                    end
                end
            end
        end

        local dura = math.ceil( tech_conf.Dura / ( 1 + self:get_num( "SpeedTech_R" ) * 0.0001 ) )
        if not self:do_consume_quick( tech_conf.Cons, dura, VALUE_CHANGE_REASON.LEARN_TECH) then return end
        self:do_learn_tech( build, tech_id)
        self:add_count( resmng.ACH_COUNT_RESEARCH, 1 )

        return reply_ok( self, "learn_tech", 0)

    else
        if not self:consCheck(tech_conf.Cons) then return end
        self:consume(tech_conf.Cons, 1, VALUE_CHANGE_REASON.LEARN_TECH)

        build.state = BUILD_STATE.WORK
        build.tmStart = gTime
        build.extra = { count=tech_conf.Dura, id=tech_id }
        build:recalc()
        return reply_ok( self, "learn_tech", 0)
    end
end



--------------------------------------------------------------------------------
-- Function : 升级科技
-- Argument : self, tech_id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function do_learn_tech(self, academy, tech_id)
    local conf = resmng.get_conf("prop_tech", tech_id)
    if not conf then
        ERROR("do_learn_tech: get prop_tech config failed. pid = %d, tech_id = %d.", self.pid, tech_id or -1)
        return
    end

    local tech = self.tech
    -- remove old tech
    if conf.Lv > 1 then
        local old_tech_id = tech_id - 1
        local old_conf = resmng.get_conf("prop_tech", old_tech_id)
        if not old_conf then
            ERROR("do_learn_tech: get old prop_tech config failed. pid = %d, old_tech_id = %d", self.pid, old_tech_id)
            return
        else
            local idx = is_in_table(self.tech, old_tech_id)
            if idx then
                table.remove(tech, idx)
                self:ef_chg(old_conf.Effect, conf.Effect )
                self:dec_pow(old_conf.Pow or 0)
            else
                return
            end
        end
    else
        if is_in_table( tech, tech_id ) then return end
        self:ef_add( conf.Effect )
    end

    -- add new tech
    table.insert(tech, tech_id)
    self.tech = tech
    self:inc_pow(conf.Pow or 0)

    --任务
    task_logic_t.process_task(self, TASK_ACTION.STUDY_TECH_MUB, 1)
    task_logic_t.process_task(self, TASK_ACTION.STUDY_TECH)
    task_logic_t.process_task(self, TASK_ACTION.PROMOTE_POWER, 2, conf.Pow)
end


--------------------------------------------------------------------------------
-- Function : 拆除建筑
-- Argument : self
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function demolish(self, build_idx)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("demolish: get_build() failed. pid = %d, build_idx = %d.", self.pid, build_idx or -1)
        return
    end

    -- TODO: Class、Mode、state 校验
    -- TODO: 解除玩家身上的引用

    -- 解除英雄派遣
    if build.hero_idx > 0 then
        local hero = self:get_hero(build.hero_idx)
        if hero then
            self:hero_offduty(hero)
        end
    end


    -- TODO: 存库
    -- TODO: 通知前端结果
end


--------------------------------------------------------------------------------
-- Function : 查询主城等级
-- Argument : self
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function get_castle_lv(self)
    -- WARNING: 主城默认是第一个建筑
    local castle = self:get_build(1)
    if not castle then
        WARN( "no castle, pid=%d", self.pid)
        return 1
    end

    local conf = resmng.get_conf("prop_build", castle.propid)
    if not conf then
        WARN("get_castle_lv: no way!!!, pid=%d", self.pid)
        return 1
    else
        return conf.Lv
    end
end


--------------------------------------------------------------------------------
-- Function : 取得监狱建筑
-- Argument : self
-- Return   : succ - prison; fail - nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_prison(self)
    local prison = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.PRISON)
    if not prison then
        ERROR("get_prison: failed. pid = %d.", self.pid)
        return
    end

    return prison
end


--------------------------------------------------------------------------------
-- Function : 取得祭坛建筑
-- Argument : self
-- Return   : succ - prison; fail - nil
-- Others   : NULL
--------------------------------------------------------------------------------

function get_build_function(self, mode)
    local builds = self:get_build()
    if builds then return builds[ mode * 100 + 1] end
end


function get_altar(self)
    return get_build_function(BUILD_FUNCTION_MODE.ALTAR)
end

function get_prison(self)
    return self:get_build_function(BUILD_FUNCTION_MODE.PRISON)
end

function get_altar(self)
    return self:get_build_function(BUILD_FUNCTION_MODE.ALTAR)
end


function get_wall(self)
    return self:get_build_function(BUILD_FUNCTION_MODE.WALLS)
end

function get_drillground(self)
    return self:get_build_function(BUILD_FUNCTION_MODE.DRILLGROUNDS)
end

function get_shipyard(self)
    return self:get_build_function(BUILD_FUNCTION_MODE.SHIPYARD)
end

function get_watchtower(self)
    return self:get_build_function(BUILD_FUNCTION_MODE.WATCHTOWER)
end

function get_market(self)
    return self:get_build_function(BUILD_FUNCTION_MODE.MARKET)
end


watchtower_attacked = {}
function watchtower_get_attacked_info(self, msg_send, all_info)
    local b = self:get_watchtower()
    local cur_watchtower_lv = 1
    if b ~= nil then
        local prop_tab = resmng.prop_build[b.propid]
        if prop_tab ~= nil then
            cur_watchtower_lv = prop_tab.Lv
        end
    end
    --cur_watchtower_lv = 29
    for i = 0, cur_watchtower_lv, 1 do
        if watchtower_attacked[i] ~= nil then
            watchtower_attacked[i](msg_send, all_info)
        end
    end
end


watchtower_attacked[1] = function(msg, src)
    msg.data_id = src.data_id
    msg.owner_pid = src.owner_pid
    msg.owner_propid = src.owner_propid
    msg.owner_photo = src.owner_photo
    msg.owner_name = src.owner_name
    msg.owner_castle = src.owner_castle or nil
    msg.owner_union_name = src.owner_union_name
    msg.action = src.action
    msg.load = src.load or nil
    msg.target = copyTab(src.target)
end

watchtower_attacked[3] = function(msg, src)
    msg.owner_pos = copyTab(src.owner_pos)
end

watchtower_attacked[5] = function(msg, src)
    msg.arrived_time = src.arrived_time
end

watchtower_attacked[7] = function(msg, src)
    msg.arms_num = src.arms_num
end

watchtower_attacked[9] = function(msg, src)
    msg.heros = copyTab(src.heros)
end

watchtower_attacked[11] = function(msg, src)
    msg.arms = copyTab(src.arms)
end

watchtower_attacked[13] = function(msg, src)
    msg.arms = copyTab(src.arms)
end

watchtower_attacked[15] = function(msg, src)
    msg.genius = copyTab(src.genius)
end

watchtower_attacked[26] = function(msg, src)
    msg.tech = copyTab(src.tech)
end

watchtower_attacked[29] = function(msg, src)
    msg.equip = copyTab(src.equip)
end

function get_watchtower_info(troop, dest_load)
    local ack = get_ety(troop.owner_eid)
    local def = get_ety(troop.target_eid)
    if ack == nil or def == nil then
        return
    end
    local recv_ply = nil
    if is_ply(def) then
        recv_ply = def
        --pack_data(def)
    else
        local tmp_ply = getPlayer(def.pid)
        if tmp_ply ~= nil then
            recv_ply = tmp_ply
            --pack_data(tmp_ply)
        end
    end
    if recv_ply == nil or recv_ply:is_online() == false then
        return
    end


    local ack_info = {}
    ack_info.data_id = troop._id
    ack_info.owner_pid = ack.pid or 0
    ack_info.owner_photo = ack.photo or 0
    ack_info.owner_name = ack.name or ""
    ack_info.owner_propid = ack.propid
    ack_info.owner_pos = {}
    ack_info.owner_pos[1] = troop.sx
    ack_info.owner_pos[2] = troop.sy
    local owner_union = unionmng.get_union(troop.owner_uid)
    if owner_union ~= nil then
        ack_info.owner_union_sn = owner_union.new_union_sn
        ack_info.owner_union_name = owner_union.alias
    end
    ack_info.load = dest_load

    ack_info.target = {}
    if is_ply(def) then
        ack_info.target.is_castle = 1
    end
    ack_info.target.prop_id = def.propid
    ack_info.target.pos = {}
    ack_info.target.pos[1] = troop.dx
    ack_info.target.pos[2] = troop.dy
    local target_union = unionmng.get_union(troop.target_uid)
    if target_union ~= nil then
        ack_info.target_union_name = target_union.alias
    end

    ack_info.arrived_time = {troop.tmStart, troop.tmOver}
    ack_info.action = troop:get_base_action()

    local owner_arms = troop:get_arm_by_pid(ack_info.owner_pid)
    if not owner_arms then
        WARN( "troop = %d, action = %d, pid = %d", troop._id, troop.action, ack_info.owner_pid )
    else
        ack_info.heros = {}
        for k, v in pairs(owner_arms.heros or {}) do
            if v ~= 0 then
                if ack_info.owner_pid == 0 then --怪物部队
                    local prop_boss_hero = resmng.get_conf("prop_boss_hero", v)
                    if prop_boss_hero then
                        table.insert(ack_info.heros, {prop_boss_hero.PropID, prop_boss_hero.Lv, prop_boss_hero.Star})
                    end
                else
                    local hero_data = heromng.get_hero_by_uniq_id(v)
                    if hero_data then
                        table.insert(ack_info.heros, {hero_data.propid, hero_data.lv, hero_data.star})
                    else
                        WARN("can not get hero, id = %s", v)
                    end
                end
            end
        end
    end

    ack_info.arms = {}
    ack_info.arms_num = 0

    for k, v in pairs(troop.arms or {}) do
        for i, j in pairs(v.live_soldier or {}) do
            if ack_info.arms[i] == nil then
                ack_info.arms[i] = 0
            end
            ack_info.arms[i] = ack_info.arms[i] + j
            ack_info.arms_num = ack_info.arms_num + j
        end
    end
    if ack_info.action == TroopAction.SupportArm then
        ack_info.load = ack_info.arms_num
    end


    if is_ply(ack) then
        ack_info.genius = {}
        table.insert(ack_info.genius, {1,0})
        table.insert(ack_info.genius, {2,0})
        table.insert(ack_info.genius, {3,0})
        for k, v in pairs(ack.genius) do
            local prop_tab = resmng.prop_genius[v]
            local class = prop_tab.Class
            if class == 1 then
                ack_info.genius[1][2] = ack_info.genius[1][2] + prop_tab.Lv
            elseif class == 2 then
                ack_info.genius[2][2] = ack_info.genius[2][2] + prop_tab.Lv
            elseif class == 3 then
                ack_info.genius[3][2] = ack_info.genius[3][2] + prop_tab.Lv
            end
        end

        ack_info.tech = {}
        for k, v in pairs(ack.tech) do
            table.insert(ack_info.tech, v)
        end

        ack_info.equip = {}
        for k, v in pairs(ack._equip) do
            table.insert(ack_info.equip, v.propid)
        end

        --主城等级
        ack_info.owner_castle = ack:get_castle_lv()
    end

    local msg_watch = {}
    recv_ply:watchtower_get_attacked_info(msg_watch, ack_info)
    Rpc:add_compensation_info(recv_ply, msg_watch)
end

function fill_watchtower_info(self, troop)
    if troop == nil or troop:is_back() == true then
        return
    end

    local base_action = troop:get_base_action()
    if WatchTowerAction[base_action] == nil then
        return
    end

    local dest_load = nil
    if base_action == TroopAction.SupportRes then --如果是物资援助，要把负重算出来
        dest_load = 0
        for k, v in pairs(troop.goods or {}) do
            if v[3] > 0 then
                dest_load = dest_load + math.floor(v[3] * RES_RATE[k])
            end
        end
    end

    player_t.get_watchtower_info(troop, dest_load)
end

function packet_watchtower_info(self)
    for k, v in pairs(self.troop_comings or {}) do
        local troop = troop_mng.get_troop(k)
        self:fill_watchtower_info(troop)
    end
end

function rm_watchtower_info(troop)
    local ply = nil
    ply = getPlayer(troop.target_pid)
    if ply == nil then
        local ety = get_ety(troop.target_eid)
        ply = getPlayer(ety.pid)
    end
    if ply == nil then
        return
    end

    Rpc:rm_compensation_info(ply, troop._id)
end

function update_watchtower_speed(troop)
    local action = troop:get_base_action()

    if WatchTowerAction[action] then
        local ply = get_ety(troop.target_eid)
        if not ply then return end
        local recv_ply = nil
        if is_ply(ply) then
            recv_ply = ply
        else
            local tmp_ply = getPlayer(ply.pid)
            if tmp_ply ~= nil then
                recv_ply = tmp_ply
            end
        end

        if recv_ply then
            local b = recv_ply:get_watchtower()
            local cur_watchtower_lv = 1
            if b ~= nil then
                local prop_tab = resmng.prop_build[b.propid]
                if prop_tab ~= nil then
                    cur_watchtower_lv = prop_tab.Lv
                end
            end
            --cur_watchtower_lv = 29
            if cur_watchtower_lv >= 5 then
                Rpc:update_compensation_info(recv_ply, troop._id, troop.tmOver)
            end
        end
    end
end

function get_store_house(self)
    local idx = self:calc_build_idx(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.STOREHOUSE)
    return self:get_build(idx)
end



function get_black_market(self)
    local bidx = self:calc_build_idx(BUILD_CLASS.FUNCTION , BUILD_FUNCTION_MODE.BLACKMARKET)
    return self:get_build(bidx)
end

function get_resource_market(self)
    local bidx = self:calc_build_idx(BUILD_CLASS.FUNCTION , BUILD_FUNCTION_MODE.RESOURCESMARKET)
    return self:get_build(bidx)
end

function do_refresh_black_market_items()
    local count = 0
    local its = {}
    local items = {}
    local valid = 0
    for i = 1, 64, 1 do
        local rate = math.random(1, TOTAL_RATE)
        local cur = 0
        for k, v in pairs(resmng.prop_black_market) do
            cur = cur + v.Rate
            if rate <= cur and not its[k] then
                its[k] = 1
                valid = k
                count = count+1
                table.insert(items, k)
                break
            end
        end
        if count >= 6 then break end
    end

    if count < 6 then
        for i = count+1, 6, 1 do
            table.insert(items, valid)
        end
    end
    return items
end


function refresh_global_black_market()
    local hots = {}
    for idx, v in ipairs(resmng.prop_black_market_hot_group) do
        local group = v.Group
        local tmp = {}
        for id, item in pairs(resmng.prop_black_market_hot) do
            if item.Group == group then
                table.insert(tmp, id)
            end
        end
        local i = math.random(1, #tmp)
        hots[ idx ] = tmp[ i ]
    end
    set_sys_status("black_market", hots)
end



function black_market_buy(self, idx)
    local build = self:get_black_market()
    if not build then return end
    if idx == 0 then
        local nbuy = build:get_extra("nbuy") or 0
        nbuy = nbuy + 1
        local need = resmng.prop_black_market_hot_group[ nbuy ]
        if not need then return end
        need = need.Point
        local point = build:get_extra("point") or 0
        if point < need then return end

        local conf = resmng.get_conf("prop_black_market_hot", build:get_extra("item"))
        if conf then
            if self:condCheck(conf.Pay) then
                self:consume(conf.Pay, 1, VALUE_CHANGE_REASON.BLACK_MARKET_PAY)
                self:add_bonus("mutex_award", conf.Buy, VALUE_CHANGE_REASON.BLACK_MARKET_BUY)
                build:set_extra("nbuy", nbuy)
                build:set_extra("point", point+conf.Point)
                build:set_extra("item", build:get_extra("item1"))

                local items = get_sys_status("black_market")
                local next_one = items[ nbuy + 2 ]
                if next_one then build:set_extra("item1", next_one)
                else build:set_extra( "item1", 0 ) end

                if conf.Notice == 1 then
                    local mlist = msglist.get("black_market")
                    if not mlist then mlist = msglist.new("black_market", 100, 1) end
                    if mlist then
                        local msg = mlist:msg_add({self.name, conf.ID, 1})
                    end
                end
                --任务
                task_logic_t.process_task(self, TASK_ACTION.MARKET_BUY_NUM, 1, 1)
            end
        end
        dumpTab(build.extra, "black_market")
    elseif idx >= 1 and idx <= 6 then
        local items = build:get_extra("items")
        if items then
            local id = items[ idx ]
            local conf = resmng.get_conf("prop_black_market", id)
            if conf then
                if self:condCheck(conf.Pay) then
                    self:consume(conf.Pay, 1, VALUE_CHANGE_REASON.BLACK_MARKET_PAY)
                    self:add_bonus("mutex_award", conf.Buy, VALUE_CHANGE_REASON.BLACK_MARKET_BUY)
                    --任务
                    task_logic_t.process_task(self, TASK_ACTION.MARKET_BUY_NUM, 1, 1)

                    local rate = math.random(1, TOTAL_RATE)
                    local cur = 0
                    for k, v in pairs(resmng.prop_black_market) do
                        cur = cur + v.Rate
                        if rate <= cur then
                            items[ idx ] = k
                            break
                        end
                    end

                    if conf.Notice == 1 then
                        local mlist = msglist.get("black_market")
                        if not mlist then mlist = msglist.new("black_market", 100, 1) end
                        if mlist then
                            local msg = mlist:msg_add({self.name, conf.ID, 0})
                        end
                    end
                    build:set_extra("point", build:get_extra("point") + conf.Point)
                    build:set_extra("items", items)
                    dumpTab(build.extra, "black_market")
                    return
                end
            end
        end
    end
end

----------------------mall
--[[extra = {
    itempool =
    {
        [group1] = {{rate, id}, {rate, id}},
        [group2] = {{rate, id}, {rate, id}}
    },

    goods =
    {
        [1] = {id, isbuy},
        [2] = {id, isbuy}
    }
}--]]

function init_pool(mode)
    local itemPool = {}
    for k, v in pairs(resmng.prop_mall_item) do
        local group = itemPool[v.Group] or {}
        local rate = v.Rate or 10
        group[v.ID] = {rate, v.ID}
        itemPool[v.Group] = group
    end
    return itemPool
end

function init_shelf(itemPool, mode)
    local mall = {}
    local shelf = {}
    local propType = ""
    if mode == POINT_MALL.MONSTER then
        propType = "prop_mall_group_monster"
    end
    if mode == POINT_MALL.MANOR then
        propType = "prop_mall_group_manor"
    end
    if mode == POINT_MALL.RELIC then
        propType = "prop_mall_group_relic"
    end
    local prop = resmng[propType]
    if prop then
        for k, v in pairs(prop) do
                local itemId = get_shelf_item(itemPool, v.Group)
                if itemId  then
                    local item = {}
                    item._id = v.ID
                    item.itemId = itemId
                    item.point = 0
                    item.state = 0
                    shelf[v.ID] = item
                end
        end
    end
    mall.born_time = gTime
    mall.next_time = get_next_time()
    mall.nrefresh = 0
    mall.shelf = shelf
    return mall
end

function get_shelf_item(itemPool, group)
    if itemPool then
        local pool = itemPool[group]
        if pool then
            local item = get_item_id(pool)
            if item then
                pool[item[2]] = nil
                itemPool[group] = pool
                return item[2]
            end
        end
    end
end

function get_item_id(pool)
    local totalRate = 0
    local cur = 0
    for k, v in pairs(pool) do
        totalRate = totalRate + v[1]
    end
    local rate = math.random(1, totalRate)
    for k, v in pairs(pool) do
        cur = cur + v[1]
        if cur >= rate then
            return v
        end
    end
end

function get_mall_build(self, mode)
    local mallType = BUILD_FUNCTION_MODE.DAILYQUEST
    local bidx = self:calc_build_idx(BUILD_CLASS.FUNCTION , mallType)
    local build = self:get_build(bidx)
    return build
end

function refresh_mall(self, mode)
    local build = self:get_mall_build(mode)
    if build then
        local itemPool = init_pool(mode)
        local mall = init_shelf(itemPool, mode)
        build:set_extra(POINT_MALL_TYPE[mode], mall)
    end
end

---积分商城在行宫中
function get_mall(ply, mode)
    local build = ply:get_mall_build(mode)
    if not build then
        return
    end
    local mall = build:get_extra(POINT_MALL_TYPE[mode])
    if not mall or need_refresh(mall) then

        local itemPool = init_pool(mode)
        mall = init_shelf(itemPool, mode)
        build:set_extra(POINT_MALL_TYPE[mode], mall)
    end
    return mall
end

function need_refresh(mall)
    return can_date(mall.born_time)
end

function mall_info(self, mode)
    local mall = self:get_mall(mode)
    if mall then
        return mall
    end
end

function mall_buy(self, mode, idx)
    local build = self:get_mall_build(mode)
    local mall = self:get_mall(mode)
    if mall then
        local shelf = mall.shelf
        if not shelf then return end
        local item = shelf[ idx ]
        local conf = resmng.get_conf("prop_mall_item", item.itemId)
        if conf and item.state ~= 1 then
            if self:condCheck(conf.Pay) then
                self:consume(conf.Pay, 1, VALUE_CHANGE_REASON.PT_MALL_BUY)
                self:add_bonus("mutex_award", conf.Buy, VALUE_CHANGE_REASON.PT_MALL_BUY,1, false)
                --任务
                task_logic_t.process_task(self, TASK_ACTION.MARKET_BUY_NUM, 1, 1)


                --[[if conf.Notice == 1 then
                local mlist = msglist.get("black_market")
                if not mlist then mlist = msglist.new("black_market", 100, 1) end
                if mlist then
                local msg = mlist:msg_add({self.name, conf.ID, 0})
                end
                end--]]
                item.state = 1
                shelf[idx] = item

                return
            end
        end
    end
end



-- extra = { items = {1001001,1002001,...}, item=1001001, nbuy=1, nfresh=3 }
-- extra = { items = {1001001,1002001,...}, item=1001001, nbuy=1, nfresh=3, point=0, item1=1001002}
function refresh_black_marcket(self)
    local black_market = self:get_black_market()
    if black_market then
        local items = do_refresh_black_market_items()
        local hots = get_sys_status("black_market")
        black_market:set_extras({ items=items, item=hots[1], item1=hots[2], nfresh=0, nbuy=0, point=0})
        dumpTab(black_market.extra, "black_market")
    end
end


-- rpc
function black_market_refresh(self)
    local build = self:get_black_market()
    if not build then return end

    local info = build.extra
    local nfresh = info.nfresh + 1

    local cost = BLACK_MARKET_REFRESH_COST[ nfresh ]
    if not cost then cost = BLACK_MARKET_REFRESH_COST[  #BLACK_MARKET_REFRESH_COST ] end

    if self:get_res_num(resmng.DEF_RES_GOLD) >= cost then
        self:do_dec_res(resmng.DEF_RES_GOLD, cost, VALUE_CHANGE_REASON.BLACK_MARKET_REFRESH)
        local items = do_refresh_black_market_items()
        build:set_extra("items", items)
        build:set_extra("nfresh", nfresh)
    end
end

---rpc
function refresh_mall_req(self, mode)
    local build = self:get_mall_build(mode)
    local mall = self:get_mall(mode)
    if not mall then return end
    local nrefresh = mall.nrefresh + 1
    local prop = resmng.prop_mall_refresh[nrefresh]
    if not prop then
        prop = resmng.prop_mall_refresh[#resmng.prop_mall_refresh]
    end
    local cost = prop[MALL_PAY_TYPE[mode]]
    if not cost then return end
    if self:condCheck(cost) then
        self:consume(cost, 1, VALUE_CHANGE_REASON.PT_MALL_REFRESH)
        self:add_bonus("mutex_award", cost, VALUE_CHANGE_REASON.PT_MALL_REFRESH)

        local itemPool = init_pool(mode)
        mall = init_shelf(itemPool, mode)
        mall.nrefresh = nrefresh
        build:set_extra(POINT_MALL_TYPE[mode], mall)
        kw_mall_info_req(self, mode)
    end
end

function open_field( self, index )
    if index ~= self.field + 1 then return end
    --todo, how can
    local node = resmng.prop_open_field[ index ]
    if not node then return end

    if self:condCheck(node.Cond) and self:consCheck(node.Cons) then
        self:consume(node.Cons, 1, VALUE_CHANGE_REASON.BUILD_CONSTRUCT)
        self.field = index

        --任务
        task_logic_t.process_task(self, TASK_ACTION.OPEN_RES_BUILD, self.field)
    end
end


function acc_res( self, build_idx, item_idx )
    local build = self:get_build( build_idx )
    local item = self:get_item( item_idx )

    if not build or not item then return end
    local prop = resmng.get_conf( "prop_build", build.propid )
    if not prop then return end
    if prop.Class ~= BUILD_CLASS.RESOURCE then return end
    local mode = prop.Mode

    if item[2] ~= resmng.ACC_RES_ITEM[ mode ] then return end
    if not self:dec_item( item_idx, 1, VALUE_CHANGE_REASON.USE_ITEM ) then return end

    build:add_buf( resmng.ACC_RES_BUFF[ mode ], 24 * 3600 )
    reply_ok( self, "acc_res", build_idx )
end

function acc_res_gold( self, build_idx )
    local build = self:get_build( build_idx )
    if not build then return end

    local prop = resmng.get_conf( "prop_build", build.propid )
    if not prop then return end
    if prop.Class ~= BUILD_CLASS.RESOURCE then return end
    local mode = prop.Mode

    local gold = resmng.ACC_RES_COST[ mode ]
    if self:get_res_num(resmng.DEF_RES_GOLD) >= gold  then
        self:do_dec_res(resmng.DEF_RES_GOLD, gold, VALUE_CHANGE_REASON.BUILD_ACC)
        build:add_buf( resmng.ACC_RES_BUFF[ mode ], 24 * 3600 )
        reply_ok( self, "acc_res", build_idx )
    end
end

function destroy_build( self, build_idx )
    local build = self:get_build( build_idx )
    if not build then return end

    local prop = resmng.get_conf( "prop_build", build.propid )
    if not prop then return end

    local max = BUILD_MAX_NUM[ prop.Class ]
    if not max then return end

    max = max[ prop.Mode ]
    if not max then return end

    if max < 2 then return end

    if build.state == BUILD_STATE.WAIT or ( build.state == BUILD_STATE.WORK and build:is_res() ) then
        local dura = prop.Lv * DESTROY_FIELD_FACTOR
        if not self:check_build_queue( dura ) then return end

        build.state = BUILD_STATE.DESTROY
        build.tmStart = gTime
        build.tmOver = gTime + dura
        build.tmSn = timer.new( "build", dura, self.pid, build_idx )
        self:dispatch_hero( build.idx, 0 )

        self:mark_build_queue( build_idx )

        reply_ok( self, "destroy_build", 0 )
    end
end

function build_action_cancel( self, build_idx )
    local build = self:get_build( build_idx )
    if not build then return end

    local prop = resmng.get_conf( "prop_build", build.propid )
    if not prop then return end

    if build.state == BUILD_STATE.UPGRADE then
        prop = resmng.get_conf( "prop_build", prop.ID + 1 )
        if not prop then return end
        self:clear_build_queue( build.idx )
        build.state = BUILD_STATE.WAIT
        build.tmStart = gTime
        build.tmOver = 0
        if build.tmSn and build.tmSn > 0 then timer.del( build.tmSn ) end
        build.tmSn = 0

        self:obtain( prop.Cons, CANCEL_BUILD_FACTOR, VALUE_CHANGE_REASON.CANCEL_ACTION )
        if build:is_res() then
            build.state = BUILD_STATE.WORK
            build:init_speed()
        end
    elseif build.state == BUILD_STATE.DESTROY then
        self:clear_build_queue( build.idx )
        build.state = BUILD_STATE.WAIT
        build.tmStart = gTime
        build.tmOver = 0
        if build.tmSn and build.tmSn > 0 then timer.del( build.tmSn ) end
        build.tmSn = 0
        if build:is_res() then
            build.state = BUILD_STATE.WORK
            build:init_speed()
        end

    elseif build.state == BUILD_STATE.WORK then
        if build:is_academy() then
            local id = build:get_extra("id")
            if not id then return end
            local conf = resmng.get_conf("prop_tech", id)
            if not conf then return end
            self:obtain( conf.Cons, CANCEL_BUILD_FACTOR, VALUE_CHANGE_REASON.CANCEL_ACTION )
            build.state = BUILD_STATE.WAIT
            build.tmStart = gTime
            build.tmOver = 0
            if build.tmSn and build.tmSn > 0 then timer.del( build.tmSn ) end
            build.tmSn = 0
            build.extra = {}

        elseif build:is_forge() then
            local id = build:get_extra("forge")
            if not id then return end
            local silver = build:get_extra( "silver" )
            if not silver then return end
            local n = resmng.get_conf("prop_equip", id)
            if not n then return end
            self:obtain( n.Cons, 1, VALUE_CHANGE_REASON.FORGE_CANCEL )
            self:obtain( {{1,8,silver}}, 0.6, VALUE_CHANGE_REASON.FORGE_CANCEL )
            build.state = BUILD_STATE.WAIT
            build.tmStart = gTime
            build.tmOver = 0
            if build.tmSn and build.tmSn > 0 then timer.del( build.tmSn ) end
            build.tmSn = 0
            build.extra = {}

        elseif prop.Class == BUILD_CLASS.ARMY then
            local id = build:get_extra( "id" )
            local num = build:get_extra( "num" )
            local conf = resmng.get_conf( "prop_arm", id )
            if conf then
                self:obtain( conf.Cons, num * CANCEL_BUILD_FACTOR, VALUE_CHANGE_REASON.CANCEL_ACTION )
            end

            build.state = BUILD_STATE.WAIT
            build.tmStart = gTime
            build.tmOver = 0
            if build.tmSn and build.tmSn > 0 then timer.del( build.tmSn ) end
            build.tmSn = 0
            build.extra = {}

        end
    end
end

function wall_fire( self, dura )
    local wall = self:get_wall()
    if not wall then return end
    if dura < 0 then return end

    local fire = wall:get_extra( "fire" )
    if not fire then
        local prop = resmng.get_conf( "prop_build", wall.propid )
        local cur = prop.Param.Defence
        fire = gTime
        if is_in_black_land( self.x, self.y ) then
            timer.new( "city_fire", 1, self.pid )
        else
            timer.new( "city_fire", 18, self.pid )
        end
        fire = gTime
    end
    wall:set_extra( "fire", fire + dura )

    local cur = wall:get_extra( "cur" )
    if not cur then
        local conf = resmng.get_conf( "prop_build", wall.propid )
        if not conf then return end
        cur = conf.Param.Defence
        wall:set_extra( "cur", cur )
        if is_in_black_land( self.x, self.y ) then
            wall:set_extra( "black", 1 )
            wall:set_extra( "cur", cur - WALL_FIRE_IN_BLACK_LAND )
        else
            wall:set_extra( "black", 0 )
            wall:set_extra( "cur", cur - 1)
        end
    end

    local last = wall:get_extra( "last" )
    if not last or gTime - last > WALL_FIRE_REPAIR_TIME then wall:set_extra( "last", 0 ) end
end


function wall_repair( self, mode ) -- mode == 0; free, mode == 1, use gold; mode == 2, use item
    local wall = self:get_wall()
    if not wall then return end

    local cur = wall:get_extra( "cur" )
    if not cur then return end

    local prop = resmng.get_conf( "prop_build", wall.propid )
    local max = prop.Param.Defence

    if mode == 0 then
        local last = wall:get_extra( "last" )
        if last and gTime - last < WALL_FIRE_REPAIR_TIME then return end
        cur = cur + WALL_FIRE_REPAIR_FREE
        if cur > max then cur = max end
        wall:set_extra( "last", gTime )

    elseif mode == 1 then
        local cost = math.ceil( ( max - cur ) / 300 ) * 20
        if cost < 1 then return end
        if self.gold < cost then return end
        self:do_dec_res( resmng.DEF_RES_GOLD, cost, VALUE_CHANGE_REASON.WALL_REPAIR)
        cur = max

    elseif mode == 2 then
        if self:dec_item_by_item_id( resmng.ITEM_PROMPTLY_RECOVERY, 1, VALUE_CHANGE_REASON.WALL_REPAIR ) then
            cur = max
        else
            return
        end
    end

    if cur >= max then
        local fire = wall:get_extra( "fire" )
        if not fire or fire < gTime then
            wall:clr_extras( { "cur", "last", "fire", "black" } )
        else
            wall:set_extra( "cur", max )
        end
    else
        wall:set_extra( "cur", cur )
    end
    return true
end



function wall_outfire( self )
    local wall = self:get_wall()
    if not wall then return end

    local fire = wall:get_extra( "fire" )
    if not fire or fire < gTime then
        wall:clr_extra( "fire" )
        return
    end

    if self.gold < WALL_FIRE_OUTFIRE_COST then return end
    self:do_dec_res( resmng.DEF_RES_GOLD, WALL_FIRE_OUTFIRE_COST, VALUE_CHANGE_REASON.WALL_REPAIR)
    wall:clr_extra( "fire" )
end


-- for item use api
function wall_recover( self )
    self:wall_repair( 2 )
end

