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
    local info = db.build:find({pid=self.pid})
    local bs = {}
    while info:hasNext() do
        local b = info:next()
        bs[ b.idx ] = build_t.new(b)
    end
    for _, v in pairs(bs) do
        local node = resmng.prop_build[ v.propid ]
        if node and node.Effect then
            self:ef_add(node.Effect or {}, true)
        end
        v.name = node.Name
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
    --local max_seq = (BUILD_MAX_NUM[build_class] and BUILD_MAX_NUM[build_class][build_mode]) or 1
    --if not max_seq then
    --    ERROR("calc_build_idx: get max_seq failed. pid = %d, build_class = %d, build_mode = %d.", self.pid, build_class or -1, build_mode or -1)
    --    return
    --end

    --if not build_seq then
    --    for seq = 1, max_seq do
    --        local build_idx = self:calc_build_idx(build_class, build_mode, seq)
    --        local build = self:get_build(build_idx)
    --        if build then return build_idx end
    --    end
    --else
    --    if build_seq < 0 or build_seq > max_seq then
    --        ERROR("calc_build_idx: build_seq = %d, max_seq = %d.", build_seq, max_seq)
    --        return
    --    end

    --    return build_class * 100 * 100 + build_mode * 100 + build_seq
    --end
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
        ERROR("get_build_extra: get_build() failed. pid = %d, build_idx = %d.", self.pid, build_idx)
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


function get_castle_lv(self)
    local bs = self:get_build()
    for k, v in pairs(bs) do
        local propid = v.propid
        local n = resmng.prop_build[ propid ]
        if n and n.Class == 0 and n.Mode == 0 then
            return n.Lv
        end
    end
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
    if node and node.Lv == 1 then
        if self:condCheck(node.Cond) and self:consCheck(node.Cons) then
            local id = string.format("_%d", self.pid)
            local idx = self:get_new_idx(node.Class, node.Mode)
            if idx then
                self:consume(node.Cons, 1, VALUE_CHANGE_REASON.BUILD_CONSTRUCT)

                local t = build_t.create(idx, self.pid, node.ID, x, y, BUILD_STATE.CREATE, gTime, gTime+node.Dura)
                t.tmSn = timer.new("build", node.Dura, self.pid, idx)
                self:set_build(idx, t)
                Rpc:stateBuild(self, t._pro)


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
            local id = node.ID + 1
            local dst = resmng.prop_build[ id ]
            if dst then
                if self:condCheck(dst.Cond) and self:consCheck(dst.Cons) then
                    self:consume(dst.Cons, 1, VALUE_CHANGE_REASON.BUILD_UPGRADE)
                    build.state = BUILD_STATE.UPGRADE
                    build.tmStart = gTime
                    build.tmOver = gTime + dst.Dura
                    build.tmSn = timer.new("build", dst.Dura, self.pid, idx)

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
            if dst.Pow then self:inc_pow(dst.Pow) end

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
                    --接收每日任务
                    self:take_daily_task()
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
            --任务
            task_logic_t.process_task(self, TASK_ACTION.CITY_BUILD_LEVEL_UP)
            task_logic_t.process_task(self, TASK_ACTION.CITY_BUILD_MUB, 1)
            task_logic_t.process_task(self, TASK_ACTION.PROMOTE_POWER, 1, dst.Pow)

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
        ERROR("one_key_upgrade_build: build._id = %s, build.state(%d) ~= BUILD_STATE.WAIT", build._id, build.state)
        return
    end

    local dst = resmng.get_conf("prop_build", node.ID + 1)
    if not dst then
        ERROR("one_key_upgrade_build: get next node failed. build._id = %s, build lv = %d", build._id, node.Lv)
        return
    else
        if not self:condCheck(dst.Cond) then
            ERROR("one_key_upgrade_build: check cond failed. build._id = %s", build._id)
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

            --local gold_need = calc_cons_value(cons_need_buy) + self:calc_cd_golds(dst.Dura)
            local gold_need = calc_cons_value(cons_need_buy) + calc_acc_gold(dst.Dura)
            if gold_need > 0 and gold_need > self.gold then
                ERROR("one_key_upgrade_build: pid = %d, player.gold(%d) < gold_need(%d)", self.pid, self.gold, gold_need)
                return
            else
                -- 扣除 cons_have 和 gold_need
                self:dec_cons(cons_have, VALUE_CHANGE_REASON.BUILD_UPGRADE, true)
                if gold_need > 0 then
                    self:do_dec_res(resmng.DEF_RES_GOLD, gold_need, VALUE_CHANGE_REASON.BUILD_UPGRADE)
                end

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
                self:inc_pow(node.Pow)
                if node.Effect then self:ef_add(node.Effect) end
                if node.Class == BUILD_CLASS.RESOURCE then 
                    build.state = BUILD_STATE.WORK
                    build:init_speed()
                    --任务
                    task_logic_t.process_task(self, TASK_ACTION.RES_OUTPUT)
                end
                task_logic_t.process_task(self, TASK_ACTION.CITY_BUILD_LEVEL_UP)

                if build.propid == resmng.BUILD_BLACKMARKET_1 then
                    self:refresh_black_marcket()
                end

                if build.propid == resmng.BUILD_RESOURCESMARKET_1 then
                    self:refresh_black_marcket()
                end


            end
        elseif state == BUILD_STATE.UPGRADE then
            self:do_upgrade(build_idx)

        elseif state == BUILD_STATE.DESTROY then
            self._build[ build_idx ] = nil
            Rpc:stateBuild( self, { idx=build.idx, delete=true } )
            gPendingDelete.build[ build._id ] = 0
            build_t._cache[ build._id ] = nil


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
                    self:do_learn_tech(build, arg_1)
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
                            timer.new("destroy_dead_hero", RELIVE_HERO_DAYS_LIMIT * 24 * 60 * 60, hero._id)

                            local buff = build:get_extra("buff")
                            if buff and buff.over > gTime then
                                self:rem_buf(buff.id, buff.over)
                            end

                            local newbuf = self:add_buf(buff_id, buff_time)
                            build:set_extra("buff", {id=buff_id, start=gTime, over=newbuf[2]})
                        end
                    end

                elseif conf.Mode == BUILD_FUNCTION_MODE.FORGE then
                    local tid = build:get_extra_val("forge")
                    if tid then
                        self:equip_add(tid, VALUE_CHANGE_REASON.FORGE)
                        --任务
                        task_logic_t.process_task(self, TASK_ACTION.MAKE_EQUIP, tid, 1)
                        task_logic_t.process_task(self, TASK_ACTION.GET_EQUIP, tid, 1)
                    end
                    build:clr_extra("forge")

                end

            elseif conf.Class == BUILD_CLASS.RESOURCE then
                -- 资源生产
                if conf.Mode == BUILD_RESOURCE_MODE.FARM then
                    -- 农田
                    -- "FoodSpeed"
                elseif conf.Mode == BUILD_RESOURCE_MODE.LOGGINGCAMP then
                    -- 伐木场
                    -- "WoodSpeed"
                elseif conf.Mode == BUILD_RESOURCE_MODE.MINE then
                    -- 铁矿
                    -- "IronSpeed"
                elseif conf.Mode == BUILD_RESOURCE_MODE.QUARRY then
                    -- 能源石
                    -- "EnergySpeed"
                end
            elseif conf.Class == BUILD_CLASS.ARMY then
                -- 造兵
                -- 'TrainSpeed'
                if conf.Mode == BUILD_ARMY_MODE.BARRACKS then
                    -- 兵营
                elseif conf.Mode == BUILD_ARMY_MODE.STABLES then
                    -- 马厩
                elseif conf.Mode == BUILD_ARMY_MODE.RANGE then
                    -- 靶场
                elseif conf.Mode == BUILD_ARMY_MODE.FACTORY then
                    -- 工坊
                end
            end
        end
    end
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
    if prop_tab == nil then
        return
    end
    if prop_tab.Class == 1 and build.state == BUILD_STATE.WORK then
        ERROR("res build can`t acc: pid = %d, build_idx = %d, build.state = %d", self.pid, build_idx, build.state)
        return 
    end

    --if build.state == BUILD_STATE.DESTROY or build.state == BUILD_STATE.WAIT then
    if build.state == BUILD_STATE.WAIT then
        ERROR("acc_build: pid = %d, build_idx = %d, build.state = %d", self.pid, build_idx, build.state)
        return
    end

    if acc_type == ACC_TYPE.FREE then
        if build:can_acc_for_free() then
            build:acceleration(build.tmOver - gTime)
        end
    elseif acc_type == ACC_TYPE.GOLD then
        local num = calc_acc_gold(build.tmOver - gTime)
        if self:get_res_num(resmng.DEF_RES_GOLD) >= num  then
            self:do_dec_res(resmng.DEF_RES_GOLD, num, VALUE_CHANGE_REASON.BUILD_ACC)
            --任务
            task_logic_t.process_task(self, TASK_ACTION.GOLD_ACC, 1)
            build:acceleration(build.tmOver - gTime)
        end
    else
        ERROR("acc_build: pid = %d, build_idx = %d, acc_type = %d", self.pid, build_idx, acc_type or -1)
        return
    end
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

-- 收获
function reap(self, idx)
    local n = self:get_build(idx)
    if n then
        if n.state ~= BUILD_STATE.WORK then return end
        if gTime - n.tmStart < 60 then return end

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

        if speed == 0 then 
            n:init_speed() 
            return
        end

        cache = math.floor(cache + speed * (gTime - start) / 3600)
        if cache > count then cache = count end

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

    if not self:condCheck(n.Cons) then return LOG("forge, pid=%d, state=%d", self.pid, b and b.state or -1) end
    self:consume(n.Cons, 1, VALUE_CHANGE_REASON.FORGE)

    b.state = BUILD_STATE.WORK
    b.tmStart = gTime
    b.tmOver  = gTime + n.Dura
    b.tmSn    = timer.new("build", n.Dura, self.pid, b.idx)
    b:update_extra({forge=id})
end

function equip_split(self, id)
    print("equip_split", id)
    local n = self:get_equip(id)
    if not n then return LOG("equip_split, no equip") end
    if n.pos ~= 0 then return end -- equip_on

    local prop = resmng.get_conf("prop_equip", n.propid)
    if not prop then return LOG("equip_split, no prop") end

    self:obtain(n.Split, 1, VALUE_CHANGE_REASON.SPLIT)
    self:equip_rem(id, VALUE_CHANGE_REASON.SPLIT)

    --if not prop.Split then return LOG("equip_split, no prop.Split") end

    --local total = 0
    --for _, v in pairs(prop.Split) do
    --    total = total + v[2]
    --end

    --if total < 1 then return LOG("equip_split, no total") end
    --local rate = math.random(1, total)

    --local cur = 0
    --local rare = false
    --for _, v in pairs(prop.Split) do
    --    cur = cur + v[2]
    --    if rate <= cur then
    --        rare = v[1]
    --        break
    --    end
    --end

    --if not rare then return LOG("equip_split, no rare") end

    --local group = get_material_group_by_rare(rare)
    --if group and #group > 0 then
    --    local its = {}
    --    for i = 1, prop.SplitNum do
    --        local idx = math.random(1, #group)
    --        local tid = group[ idx ]
    --        its[ tid ] = (its[ tid ] or 0) + 1
    --    end

    --    for k, v in pairs(its) do
    --        self:inc_item(k, v, VALUE_CHANGE_REASON.SPLIT)
    --    end

    --    self:equip_rem(id, VALUE_CHANGE_REASON.SPLIT)
    --    return
    --end

    --if not rare then return LOG("equip_split, no group") end
end


-- 训练
function train(self, idx, armid, num)
    -- check params
    local build = self:get_build(idx)
    if not build then return end

    if build.state ~= BUILD_STATE.WAIT then return end
    local bnode = resmng.prop_build[ build.propid ]
    if not bnode then return end
    if bnode.Class ~= 2 then return self:addTips("class~=2") end

    local anode = resmng.prop_arm[ armid ]
    if not anode then return self:addTips("no armid") end
    if anode.Mode ~= bnode.Mode then return self:addTips("mode") end

    if anode.Lv > bnode.TrainLv then return self:addTips("lv") end

    local maxTrain = self:get_val("CountTrain")
    if num > maxTrain then return self:add_debug("CountTrain") end

    -- check resources
    if not self:condCheck(anode.Cond) then return false end
    if not self:consCheck(anode.Cons, num) then return false end
    self:consume(anode.Cons, num, VALUE_CHANGE_REASON.TRAIN)

    local dura = num * anode.TrainTime
    build.tmStart = gTime
    build.extra = { count = dura }
    build:recalc()
    build:set_extras({id=armid, num=num})
    build.state = BUILD_STATE.WORK

    dumpTab(build.extra, "build_train")
end

-- 征募
function draft(self, idx)
    local build = self:get_build(idx)
    if not build then return end
    if build.state ~= BUILD_STATE.WORK then return INFO("draft, not state %s", build.state) end
    if build.tmOver > gTime then return INFO("draft, not time %d", build.tmOver - gTime) end
    build.state = BUILD_STATE.WAIT
    --Rpc:stateBuild(self, build._pro)

    local extra = build.extra
    if extra and extra.id > 0 and extra.num > 0 then
        local troop = self:get_my_troop()
        troop:add_soldier(extra.id, extra.num)
        local arm = troop:get_arm_by_pid(self.pid)

        --任务
        local soldier_type = math.floor(extra.id / 1000)
        local soldier_level = extra.id % 1000
        task_logic_t.process_task(self, TASK_ACTION.RECRUIT_SOLDIER, soldier_type, soldier_level, extra.num)
        task_logic_t.process_task(self, TASK_ACTION.GET_RES, soldier_type)
        Rpc:upd_arm(self, arm.live_soldier)

        build.extra = {}
        self:recalc_food_consume()
    end
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

    -- check & consume
    if not self:condCheck(tech_conf.Cond) then
        ERROR("learn_tech: check cond failed. pid = %d", self.pid)
        return
    end

    if is_quick == 1 then
        if not self:do_consume_quick( tech_conf.Cons, tech_conf.Dura, VALUE_CHANGE_REASON.LEARN_TECH) then return end
        self:do_learn_tech( build, tech_id)
        return reply_ok( self, "learn_tech", 0)

    else
        if not self:consCheck(tech_conf.Cons) then
            ERROR("learn_tech: check cons failed. pid = %d", self.pid)
            return
        end
        self:consume(tech_conf.Cons, 1, VALUE_CHANGE_REASON.LEARN_TECH)

        -- new timer
        --local dura = math.ceil(self:calc_real_dura("TechSpeed", tech_conf.Dura))
        local dura = tech_conf.Dura

        build.state = BUILD_STATE.WORK
        build.tmStart = gTime
        build.tmOver = gTime + dura
        build.tmSn = timer.new("learn_tech", dura, self.pid, build_idx, tech_id)

        local chg = {tech_id = tech_id, std_dura = tech_conf.Dura}
        build:set_extras(chg)
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
                self:ef_rem(old_conf.Effect)
            else
                return
            end
        end
    else
        if is_in_table( tech, tech_id ) then return end
    end

    -- add new tech
    table.insert(tech, tech_id)
    self:ef_add(conf.Effect)
    self.tech = tech
    self:inc_pow(conf.Pow)

    --任务
    task_logic_t.process_task(self, TASK_ACTION.STUDY_TECH_MUB, 1) 
    task_logic_t.process_task(self, TASK_ACTION.STUDY_TECH)
    task_logic_t.process_task(self, TASK_ACTION.PROMOTE_POWER, 2, conf.Pow)

    -- clear
    local chg = {"tech_id", "std_dura"}
    academy:clr_extras(chg)
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
-- Function : 计算不同建筑行为受buff影响后的真实耗时
-- Argument : self, effect_type, arg
-- Return   : succ - number; fail - false
-- Others   : 这里的行为仅包括 科技研究、治疗、造兵
--------------------------------------------------------------------------------
function calc_real_dura(self, effect_type, arg)
    if not effect_type or not arg then
        ERROR("calc_real_dura: effect_type= %s, arg = %d.", effect_type or "", arg)
        return false
    end

    -- TODO: 策划还没有提供计算公式，以下为临时测试使用
    if effect_type == "TechSpeed" then
        local speed = self:get_val(effect_type)
        return math.ceil(arg / speed)
    elseif effect_type == "CureSpeed" then
        -- TODO: 这里默认1秒治疗1点血
        local speed = self:get_val(effect_type)
        return math.ceil(arg / speed)
    -- elseif effect_type =="FoodSpeed" then
    -- elseif effect_type =="WoodSpeed" then
    -- elseif effect_type =="IronSpeed" then
    -- elseif effect_type =="EnergySpeed" then
    elseif effect_type =="TrainSpeed" then
        local speed = self:get_val(effect_type)
        return math.ceil(arg / speed)
    else
        ERROR("calc_real_dura: pid = %d, wrong effect_type(%s).", self.pid, effect_type)
        return false
    end
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
    local conf = resmng.get_conf("prop_build", castle.propid)
    if not conf then
        ERROR("get_castle_lv: no way!!!")
        return
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
    --cur_watchtower_lv = 30
    for i = 0, cur_watchtower_lv, 1 do
        if watchtower_attacked[i] ~= nil then
            watchtower_attacked[i](msg_send, all_info)
        end
    end
end


watchtower_attacked[1] = function(msg, src) 
    msg.data_id = src.data_id
    msg.owner_pid = src.owner_pid
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

watchtower_attacked[14] = function(msg, src)
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

    local ack_info = {}
    ack_info.data_id = troop._id
    ack_info.owner_pid = ack.pid or 0
    ack_info.owner_photo = ack.photo or 0
    ack_info.owner_name = ack.name or ""
    ack_info.owner_propid = 0
    ack_info.owner_pos = {}
    ack_info.owner_pos[1] = troop.sx
    ack_info.owner_pos[2] = troop.sy
    local owner_union = unionmng.get_union(troop.owner_uid)
    if owner_union ~= nil then
        ack_info.owner_union_name = owner_union.alias
    end
    ack_info.load = dest_load

    ack_info.target = {}
    ack_info.target.prop_id = def.propid
    ack_info.target.pos = {}
    ack_info.target.pos[1] = troop.dx
    ack_info.target.pos[2] = troop.dy
    local target_union = unionmng.get_union(troop.target_uid)
    if target_union ~= nil then
        ack_info.target_union_name = target_union.alias
    end

    ack_info.arrived_time = {troop.tmStart, troop.tmOver}
    ack_info.action = troop.action

    local owner_arms = troop:get_arm_by_pid(ack_info.owner_pid)
    ack_info.heros = {}
    for k, v in pairs(owner_arms.heros or {}) do
        if v ~= 0 then
            local hero_data = heromng.get_hero_by_uniq_id(v)
            if hero_data then
                table.insert(ack_info.heros, {hero_data.propid, hero_data.lv, hero_data.star})
            else
                WARN("can not get hero, id = %s", v)
            end
        end
    end

    ack_info.arms = {}
    ack_info.arms[1] = 0
    ack_info.arms[2] = 0
    ack_info.arms[3] = 0
    ack_info.arms[4] = 0

    for k, v in pairs(troop.arms or {}) do
        for i, j in pairs(v.live_soldier or {}) do
            local class = math.floor(i / 1000)
            ack_info.arms[class] = ack_info.arms[class] + j
        end
    end
    ack_info.arms_num = 0
    for i = 1, 4 do
        ack_info.arms_num = ack_info.arms_num + ack_info.arms[i]
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

    function pack_data(ply)
        local msg_watch = {}
        ply:watchtower_get_attacked_info(msg_watch, ack_info)
        if ply.be_ack == nil then
            ply.be_ack = {}
        end
        local tmp_unit = {}
        tmp_unit.id = troop._id
        tmp_unit.data = msg_watch
        ply.be_ack[troop._id] = tmp_unit
        Rpc:add_compensation_info(ply, msg_watch)
    end
    if is_ply(def) then
        pack_data(def)
    else
        local tmp_ply = getPlayer(def.pid)
        if tmp_ply ~= nil then
            pack_data(tmp_ply)
        end
    end
end

function packet_watchtower_info(self)
    if self.be_ack == nil then
        return
    end
    local del_array = {}
    for k, v in pairs(self.be_ack or {}) do
        local troop = troop_mng.get_troop(k)
        if troop ~= nil then
            if v.data == nil then
                player_t.get_watchtower_info(troop)
            else
                Rpc:add_compensation_info(self, v.data)
            end
        else
            table.insert(del_array, k)
        end
    end
    for k, v in pairs(del_array) do
        self.be_ack[v] = nil
    end
    return nil
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

    if ply.be_ack == nil then
        return
    end
    ply.be_ack[troop._id] = nil
    Rpc:rm_compensation_info(ply, troop._id)
end

function update_watchtower_speed(troop)
    local action = troop.action - 100
    if action ~= TroopAction.Gather
        and action ~= TroopAction.SiegePlayer
        and action ~= TroopAction.SupportArm
        and action ~= TroopAction.SupportRes
    then
        return
    end
    local ply = nil
    ply = getPlayer(troop.target_pid)
    if ply == nil then
        local ety = get_ety(troop.target_eid)
        ply = getPlayer(ety.pid)
    end
    if ply == nil then
        return
    end

    if ply.be_ack == nil or ply.be_ack[troop._id] == nil then
        return
    end
    local data = ply.be_ack[troop._id].data
    if data.arrived_time == nil then
        return
    end
    data.arrived_time[2] = troop.tmOver
    Rpc:add_compensation_info(ply, data)
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
                if next_one then build:set_extra("item1", next_one) end

                if conf.Notice == 1 then
                    local mlist = msglist.get("black_market")
                    if not mlist then mlist = msglist.new("black_market", 100, 1) end
                    if mlist then
                        local msg = mlist:msg_add({self.name, conf.ID, 1})
                    end
                end
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
        --build:set_extra("item", get_sys_status("black_item"))
        build:set_extra("items", items)
        build:set_extra("nfresh", nfresh)
        --build:set_extra("nbuy", 0)
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
        build.state = BUILD_STATE.DESTROY
        build.tmStart = gTime
        build.tmOver = gTime + dura
        build.tmSn = timer.new( "build", dura, self.pid, build_idx )
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
        build.state = BUILD_STATE.WAIT
        build.tmStart = gTime
        build.tmOver = 0
        build.tmSn = 0
        self:obtain( prop.Cons, CANCEL_BUILD_FACTOR, VALUE_CHANGE_REASON.CANCEL_ACTION )
        if build:is_res() then
            build.state = BUILD_STATE.WORK
            build:init_speed()
        end
    elseif build.state == BUILD_STATE.DESTROY then
        build.state = BUILD_STATE.WAIT
        build.tmStart = gTime
        build.tmOver = 0
        build.tmSn = 0
        if build:is_res() then
            build.state = BUILD_STATE.WORK
            build:init_speed()
        end

    elseif build.state == BUILD_STATE.WORK then
        if build:is_hospital() then
            local hurt = self.hurts
            local cure = self.cures
            local proptab = resmng.prop_arm
            local res = {}
            for id, num in pairs( cure ) do
                local prop = proptab[ id ]
                if prop then
                    hurt[ id ] = ( hurt[ id ] or 0 ) + num
                    local cons = prop.Cons
                    for _, v in pairs( cons ) do
                        local mode = v[2]
                        local pay = v[3]
                        res[ mode ] = res[ mode ] + pay * 0.5 * num * CANCEL_BUILD_FACTOR
                    end
                end
            end
            for mode, num in pairs( res ) do
                self:doObtain( resmng.CLASS_RES, mode, num, VALUE_CHANGE_REASON.CANCEL_ACTION )
            end

            self.cures = {}
            self.hurts = hurt
            self:cure_off()

        elseif build:is_academy() then
            local id = build:get_extra("tech_id")
            if not id then return end
            local conf = resmng.get_conf("prop_tech", id)
            if not conf then return end
            self:obtain( conf.Cons, CANCEL_BUILD_FACTOR, VALUE_CHANGE_REASON.CANCEL_ACTION )
            build.state = BUILD_STATE.WAIT
            build.tmStart = gTime
            build.tmOver = 0
            build.tmSn = 0

        elseif build:is_forge() then
            local id = build:get_extra("forge")
            if not id then return end
            local conf = resmng.get_conf("prop_equip", id)
            if not conf then return end
            self:obtain( conf.Cons, CANCEL_BUILD_FACTOR, VALUE_CHANGE_REASON.CANCEL_ACTION )
            build.state = BUILD_STATE.WAIT
            build.tmStart = gTime
            build.tmOver = 0
            build.tmSn = 0

        elseif prop.Class == BUILD_CLASS.ARMY then
            local id = build:get_extra( "id" )
            local num = build:get_extra( "num" )
            local conf = resmng.get_conf( "prop_arm", id )
            if not conf then return end
            self:obtain( conf.Cons, num * CANCEL_BUILD_FACTOR, VALUE_CHANGE_REASON.CANCEL_ACTION )

            build.state = BUILD_STATE.WAIT
            build.tmStart = gTime
            build.tmOver = 0
            build.tmSn = 0

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


function wall_repair( self, mode ) -- mode == 0, free, mode == 1, use gold
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

    else
        local cost = math.ceil( (max - cur) * 20 / 300 )
        if cost < 1 then return end
        if self.gold < cost then return end
        self:do_dec_res( resmng.DEF_RES_GOLD, cost, VALUE_CHANGE_REASON.WALL_REPAIR)
        cur = max
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


