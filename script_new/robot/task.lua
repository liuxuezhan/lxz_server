module("Ply")
function task(self, v, func, ...)
    local key = g_task_func_relation[func]
    --lxz(self.account..":主："..v.task_id,self.tasking[v.task_id])
    --self.tasking[v.task_id] = nil 
    if  not self.tasking[v.task_id] then
    lxz(self.account..":"..v.task_id..":"..v.task_status)
        self.tasking[v.task_id] = true
        do_task[key](self, v, ...)
    else
--        Rpc:loadData( self, "troop" )
    end
end


npc = {}
function get_npc_eid()
    for i = 1, 4095, 1 do
        local eid = i * 4096
        if npc[eid] == nil then
            npc[eid] = eid 
            return eid
        end
    end
    return nil
end


function stateHero(self,pack)
    if  not  self._hero then  
        self._hero={}
    end
    self._hero[pack.idx] = pack
end

function update_task_info(self,pack)
    if not self._task then self._task = {} end

    for _, v in pairs(pack or {} ) do 
        --lxz(self.account,"任务更新:"..v.task_id..":"..v.task_status)
        self._task[v.task_id] = v
    end
   -- lxz(self._task)
end

function main_task(self )
    if not self.tasking then self.tasking = {} end
    --lxz(self._task,self.account)
    for _, v in pairs(self._task or {} ) do 
        if v.task_id < 130020101 and  v.task_id > 130000101 then
            if v.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
                local c = resmng.prop_task_detail[v.task_id]
                if c then
                    local res = task(self, v, unpack(c.FinishCondition))
                end
            elseif (v.task_status == TASK_STATUS.TASK_STATUS_CAN_FINISH) then
                --lxz(v)
                Rpc:finish_task(self,v.task_id)
                local id = v.task_id
                while true do
                    id = id+1
                    if not self._task[id] then
                        local c = resmng.prop_task_detail[id]
                        if c then
                            --lxz("接受任务："..id)
                            Rpc:accept_task(self,{id,})
                            break
                        end
                    end
                end
            end
        end
    end

end
do_task = {}
--攻击特定ID的怪物
do_task[TASK_ACTION.ATTACK_SPECIAL_MONSTER] = function(self, v, propid )
    Rpc:request_empty_pos(self,self.x,self.y,2,{task_id=v.task_id ,key = TASK_ACTION.ATTACK_SPECIAL_MONSTER,})
    --self.tasking[v.task_id] = false
end

--攻击等级怪物
do_task[TASK_ACTION.ATTACK_LEVEL_MONSTER] = function(self, v, mode, lv, num, real_mid, real_num)
    local function get_type(mode)
        if mode <= 30 then --普通
            return 1
        elseif mode > 30 and mode <= 40 then --精英
            return 2
        elseif mode > 40 and mode <= 50 then --首领
            return 3
        elseif mode > 50 and mode <= 100 then --超级首领
            return 4
        else -- 任务
            return 5
        end
    end

    num = num - v.current_num
    if num == 0 then
        lxz()
        return
    end
    local l = get_target( self, is_monster, lv )
    local d = l[ math.random( 1, #l ) ] 
    if num == 0 then
        self.tasking[v.task_id] = false
        return 
    end
    if get_type(d.level) == mode and  lv and d.level==lv  then
        local  arm = {[1010]=100000,[2010]=100000,[3010]=100000,[4010]=100000,}
        print("打怪"..d.eid.."("..lv..")"..":"..num)
        Rpc:siege( self, d.eid, { live_soldier = arm } )
        self:eye_up(d.eid)
        num = num - 1 
    end

    self:eye_up()
    self.tasking[v.task_id] = false
end

function eye_up(self,eid)
    if  eid then
        local e = gEtys[ eid ]
        Rpc:movEye( self, gMap, e.x, e.y )
    end
    local x,y = 224,224 --3级资源带
    if not all_ety then
        for i = 1, 52 do
            y = 224
            for j = 1, 52 do
        --        print(x,y)
                Rpc:movEye( self, gMap, x, y )
                y = y + 16
            end
            x = x+ 16
        end
    end
    all_ety = true
end

--招募士兵
do_task[TASK_ACTION.RECRUIT_SOLDIER] = function(self, task_data, mode, lv, num, ...)
    if mode == 0 then mode = 1 end
    if lv == 0 then lv = 1 end
    self:train(mode,lv,num )--造兵 

end
--打开界面
do_task[TASK_ACTION.OPEN_UI] = function(self, task_data, con_id, real_id)
    Rpc:finish_open_ui(self,con_id)
    return true
end
--收获士兵/资源
do_task[TASK_ACTION.GET_RES] = function(self, d, id )
    if not self.stm then
        Rpc:getTime( self)
       self.tasking[d.task_id] = false
        return
    end
    for k, v in pairs( self._build ) do
        local conf = resmng.prop_build[ v.propid ]
        if v.state == BUILD_STATE.WORK then
            if id < 5 then
                if conf.Class == 2 and  conf.Mode == id then
                    if self.stm > v.tmOver then
                        lxz()
                        Rpc:draft( self, v.idx )
                        return 
                    else
                        Rpc:getTime( self)
                        self.tasking[d.task_id] = false
                    end
                end
            else
                if conf.Class == 1 and conf.Mode == id-4 then
                    if self.stm - v.tmStart > 60  then
                        lxz("gTime:"..self.stm,v.tmStart)
                        Rpc:reap( self, v.idx )
                        return 
                    else
                        Rpc:getTime( self)
                        self.tasking[d.task_id] = false
                    end
                end
            end
        end
    end
end

--升级城建
do_task[TASK_ACTION.CITY_BUILD_LEVEL_UP] = function(self, v, mode, num, lv)
    local class = math.floor(mode/1000)
    mode = mode%1000
    self.tasking[v.task_id] = self:build_up(class,mode,lv,num)
end

--治疗单位
do_task[TASK_ACTION.CURE] = function(self, v, type, num,f )
    if not next(self.hurts) then
        local targets = get_target( self, is_monster )
        local count = #targets
        local d = targets[ math.random( 1, count ) ] 
        local  arm = {[1010]=100000,[2010]=100000,[3010]=100000,[4010]=100000,}
        Rpc:siege( self, d.eid, { live_soldier = arm } )
                --self:remEty( d.eid )
        self.tasking[v.task_id] = false 
        return
    end

    if type == 1 then
      --  Rpc:hero_cure(self,)
    elseif type == 2 then
        lxz()
        Rpc:cure(self,self.hurts,(f or 1))
    end

end

--签到
do_task[TASK_ACTION.MONTH_AWARD] = function(self, task_data, real_num)
    Rpc:month_award_get_award(self)
end

--军团帮助次数
do_task[TASK_ACTION.UNION_HELP_NUM] = function(self, v, num )
    local f = do_task[TASK_ACTION.CURE] 
    f(self, v, 2, 0 ,0)
end

--军团科技捐献
do_task[TASK_ACTION.UNION_TECH_DONATE] = function(self, task_data, num, con_acc )
    Rpc:union_donate(self,1001,1)
end


--采集资源
do_task[TASK_ACTION.GATHER] = function(self, task_data, mode, num, con_acc )
    local l = get_target( self, is_res )
    local v = l[ math.random( 1, #l ) ] 
    local c = resmng.prop_world_unit[v.propid]
    if mode ==c.Mode  then
        local  arm = {[1010]=100000,[2010]=100000,[3010]=100000,[4010]=100000,}
        Rpc:gather( self, v.eid, { live_soldier = arm } )
        return
    end

end

--飞艇（码头）领取
do_task[TASK_ACTION.DAY_AWARD] = function(self, task_data, con_num, real_num)
    Rpc:require_online_award(self)
end

--研究科技
do_task[TASK_ACTION.STUDY_TECH] = function(self, v, id, lv)
    self.tasking[v.task_id] = tech(self,id,(lv or 1))
end

--提升英雄等级
do_task[TASK_ACTION.HERO_LEVEL_UP] = function(self, d, lv)

    if not next(self._hero) then
        Rpc:call_hero_by_piece(self,1)
        self.tasking[d.task_id] = false
        return
    end

    local idx = 0
    for k, v in pairs( self._item ) do
        if v[2]==4003003 then
            idx = k
            break
        end
    end

    for _, v in pairs( self._hero ) do
        if v.lv then
            if v.lv < lv then
                for i = v.lv+1,lv do
                    lxz()
                    Rpc:hero_lv_up(self,v.idx,idx,100)
                end
            end
        else
            self.tasking[d.task_id] = false
            return
        end
    end
end
--持有英雄数量
do_task[TASK_ACTION.HAS_HERO_NUM] = function(self, task_data, mode, star, num)
    if #self._hero < num then
        for i=#self._hero+1, num do
            Rpc:call_hero_by_piece(self,i)
        end
    end

    for _, v in pairs( self._hero ) do
        lxz(v)
        Rpc:hero_star_up(self, v.idx)
    end

end

--参与军团集结
do_task[TASK_ACTION.JOIN_MASS] = function(self, task_data, mode, num, real_type, real_num)
    if mode == 0 or mode == 1 then
        local l = get_target( self, is_monster )
        local v = l[ math.random( 1, #l ) ] 
        local  arm = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}
        Rpc:union_mass_create(self,v.eid, MassTime.Level1, { live_soldier = arm } )
        --self:remEty( v.eid )
        return
    elseif mode == 2 then
        local l = get_target( self, is_npc_city )
        local v = l[ math.random( 1, #l ) ] 
        local  arm = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}
        Rpc:union_mass_create(self,v.eid, MassTime.Level1, { live_soldier = arm } )
        return
    elseif mode == 3 then
        local l = get_target( self, is_ply )
        local v = l[ math.random( 1, #l ) ] 
        local  arm = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}
        Rpc:union_mass_create(self,v.eid, MassTime.Level1, { live_soldier = arm } )
        return
    end

end

--铸造装备
do_task[TASK_ACTION.MAKE_EQUIP] = function(self, task_data, con_grade, con_num, equip_id, real_num)
    Rpc:equip_forge(self,6)
end



--加入玩家军团
do_task[TASK_ACTION.JOIN_PLAYER_UNION] = function(self, task_data)
    if self.uid < 10000 then
        union_add(self)
    end
end

--军团设施捐献
do_task[TASK_ACTION.UNION_SHESHI_DONATE] = function(self, task_data, num, con_acc, real_num)
    Rpc:union_load( self, "build" )
end

--收集物品
do_task[TASK_ACTION.GET_ITEM] = function(self, task_data, id, num, real_id, real_num)
    Rpc:chat(self, 0, "@additem="..id.."=10000", 0 )
end
--市场购买次数
do_task[TASK_ACTION.MARKET_BUY_NUM] = function(self, task_data, mode, num, real_type, real_num)
    if mode ==1 then
        Rpc:black_market_buy(self,0)
    elseif mode ==2 then
        Rpc:buy_res(self,1)
    end
end

--资源产量
do_task[TASK_ACTION.RES_OUTPUT] = function(self, v, mode, num)
    self.tasking[v.task_id] = self:build_up(1,mode,math.ceil(num/6),1)
end

--单场战斗进行联动
do_task[TASK_ACTION.BATTLE_LIANDONG] = function(self, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--单场战斗战损比
do_task[TASK_ACTION.BATTLE_DAMAGE] = function(self, task_data, con_ratio, real_ratio)
    if real_ratio == nil then
        return false
    end

    if real_ratio > con_ratio then
        return false
    end
    add_task_process(self, task_data, 1, 1)
    return true
end

--侦查玩家城堡
do_task[TASK_ACTION.SPY_PLAYER_CITY] = function(self, task_data, con_num, con_acc, real_num)
    if con_acc == 1 then
        local cur = self:get_count(resmng.ACH_TASK_SPY_PLAYER)
        update_task_process(task_data, con_num, cur)
        return true
    end
    if real_num == nil or real_num == 0 then
        return false
    end
    add_task_process(self, task_data, con_num, real_num)
    return true
end

--单次行军加速减少时间
do_task[TASK_ACTION.SLOW_SPEED] = function(self, task_data, con_time, real_time)
    if real_time == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.SLOW_SPEED]") == false then
        add_task_process(self, task_data, 1, 1)
    end
    --------------
    if con_time > real_time then
        return false
    end
    add_task_process(self, task_data, 1, 1)
    return false
end

--攻击玩家城堡
do_task[TASK_ACTION.ATTACK_PLAYER_CITY] = function(self, task_data, con_num, con_win, con_acc, real_num, real_win)
    if con_acc == 1 then
        local cur = 0
        if con_win == 0 then
            cur = self:get_count(resmng.ACH_TASK_ATK_PLAYER_WIN) + self:get_count(resmng.ACH_TASK_ATK_PLAYER_FAIL)
        else
            cur = self:get_count(resmng.ACH_TASK_ATK_PLAYER_WIN)
        end

        update_task_process(task_data, con_num, cur)
        return true
    end

    if real_num == nil or real_win == nil then
        return false
    end

    if con_win ~= 0 and con_win ~= real_win then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--抢夺资源数量
do_task[TASK_ACTION.LOOT_RES] = function(self, task_data, con_type, con_num, con_acc, real_type, real_num)
    if con_acc == 1 then
        local ach_index = "ACH_TASK_ATK_RES"..con_type
        local cur = self:get_count(resmng[ach_index])
        update_task_process(task_data, con_num, cur)
        return true
    end

    if real_type == nil or real_num == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--侦查系统城市
do_task[TASK_ACTION.SPY_NPC_CITY] = function(self, task_data, con_type, real_type)
    if real_type == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end
    add_task_process(self, task_data, 1, 1)
    return true
end

--攻击系统城市
do_task[TASK_ACTION.ATTACK_NPC_CITY] = function(self, task_data, con_type, con_num, con_acc, real_type, real_num)
    if con_acc == 1 then
        local cur = 0
        if con_type == 0 then
            for i = 1, 5, 1 do
                cur = cur + self:get_count(resmng["ACH_TASK_ATK_NPC"..i])
            end
        else
            cur = self:get_count(resmng["ACH_TASK_ATK_NPC"..con_type])
        end
        update_task_process(task_data, con_num, cur)
        return true
    end
    if real_type == nil or real_num == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end
    add_task_process(self, task_data, con_num, real_num)
    return true
end

--占领系统城市
do_task[TASK_ACTION.OCC_NPC_CITY] = function(self, task_data, con_type, real_type)
    if real_type == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end
    add_task_process(self, task_data, 1, 1)
    return true
end



--学习英雄技能
do_task[TASK_ACTION.LEARN_HERO_SKILL] = function(self, task_data, con_pos)
    local hero_list = self:get_hero()
    for k, v in pairs(hero_list) do
        local skill = v.basic_skill[con_pos]
        if skill ~= nil and skill[1] > 0 then
            update_task_process(task_data, 1, 1)
            return true
        end
    end
    return false
end

--英雄技能等级
do_task[TASK_ACTION.SUPREME_HERO_LEVEL] = function(self, task_data, con_level)
    local hero_list = self:get_hero()
    local highest = 0
    for k, v in pairs(hero_list) do
        for i, j in pairs(v.basic_skill) do
            local prop_tab = resmng.prop_skill[j[1]]
            if prop_tab ~= nil then
                if prop_tab.Lv > highest then
                    highest = lv
                end
            end
        end
    end
    if highest > 0 then
        update_task_process(task_data, con_level, highest)
        return true
    end
    return false
end






--军团援助
do_task[TASK_ACTION.UNION_AID] = function(self, task_data, con_type, real_type)
    if real_type == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end
    add_task_process(self, task_data, con_num, real_num)
    return true
end



--收集品质装备
do_task[TASK_ACTION.GET_EQUIP] = function(self, task_data, con_grade, con_num, equip_id, real_num)
    local num = 0
    if equip_id == nil or real_num == nil then
        --遍历找一下满足条件的装备
        local equips = self:get_equip()
        if equips == nil then
            return
        end
        for k, v in pairs(equips) do
            local prop_tab = resmng.prop_equip[v.propid]
            if prop_tab ~= nil then
                if con_grade <= prop_tab.Class then
                    num = num + 1
                end
            end
        end
    else
        local prop_tab = resmng.prop_equip[equip_id]
        if prop_tab ~= nil then
            if con_grade <= prop_tab.Class then
                num = num + 1
            end
        end
    end

    add_task_process(self, task_data, con_num, num)
    return true
end

--使用道具
do_task[TASK_ACTION.USE_ITEM] = function(self, task_data, con_class, con_mode, con_id, con_num, real_id, real_num)
    if real_id == nil or real_num == nil then
        return false
    end

    if con_id == 0 then
        --比较类别
        local prop_tab = resmng.get_conf("prop_item", real_id)
        if prop_tab ~= nil and prop_tab.Class == con_class and prop_tab.Mode == con_mode then
            add_task_process(self, task_data, con_num, real_num)
        end
    else
        --比较ID
        if con_id == real_id then
            add_task_process(self, task_data, con_num, real_num)
        end
    end

    return true
end



--开启野地
do_task[TASK_ACTION.OPEN_RES_BUILD] = function(self, task_data, con_pos, real_pos)
    if (self.field - 2) < con_pos then
        return false
    end
    add_task_process(self, task_data, 1, 1)
    return true
end






--合成材料
do_task[TASK_ACTION.SYN_MATERIAL] = function(self, task_data, con_grade, con_num, material_id, real_num)
    local prop_tab = resmng.prop_item[material_id]
    if prop_tab == nil then
        return false
    end
    local real_grade = prop_tab.Color
    if real_grade == nil or real_num == nil then
        return false
    end

    if con_grade ~= 0 and con_grade ~= real_grade then
        return false
    end
    add_task_process(self, task_data, con_num, real_num)
    return true
end




--拜访NPC
do_task[TASK_ACTION.VISIT_NPC] = function(self, task_data, con_id, real_id)
    if real_id == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.VISIT_NPC]") == false then
        add_task_process(self, task_data, 1, 1)
    end
    --------------

    if con_id ~= real_id then
        return false
    end
    add_task_process(self, task_data, 1, 1)
    return true
end


--提升领主等级
do_task[TASK_ACTION.ROLE_LEVEL_UP] = function(self, task_data, con_level)
    update_task_process(task_data, con_level, self.lv)
    return true
end

--抽卡次数
do_task[TASK_ACTION.GACHA_MUB] = function(self, task_data, con_type, con_num, real_type, real_num)
    if real_type == nil or real_num == nil then
        return false
    end
    if con_type ~= real_type then
        return false
    end
    add_task_process(self, task_data, con_num, real_num)
    return true
end

--俘虏英雄
do_task[TASK_ACTION.CAPTIVE_HERO] = function(self, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--提升英雄技能
do_task[TASK_ACTION.PROMOTE_HERO_LEVEL] = function(self, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--提升英雄经验
do_task[TASK_ACTION.HERO_EXP] = function(self, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--研发科技次数
do_task[TASK_ACTION.STUDY_TECH_MUB] = function(self, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--升级城建次数
do_task[TASK_ACTION.CITY_BUILD_MUB] = function(self, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--击杀士兵数量
do_task[TASK_ACTION.KILL_SOLDIER] = function(self, task_data, con_level, con_num, con_acc, real_level, real_num)
    if con_acc == 1 then
        local total = 0
        if con_level == 0 then
            for i = 1, 10, 1 do
                total = total + self:get_count(resmng["ACH_TASK_KILL_SOLDIER"..i])
            end
        else
            total = self:get_count(resmng["ACH_TASK_KILL_SOLDIER"..con_level])
        end
        update_task_process(task_data, con_num, total)
        return true
    end

    if con_level ~= 0 and con_level ~= real_level then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--金币加速
do_task[TASK_ACTION.GOLD_ACC] = function(self, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--提升战力途径
do_task[TASK_ACTION.PROMOTE_POWER] = function(self, task_data, con_type, con_num, real_type, real_num)
    if real_type == nil or real_num == nil then
        return false
    end
    if con_type ~= 0 and con_type ~= real_type then
        return false
    end
    add_task_process(self, task_data, con_num, real_num)
    return true
end

--阵亡士兵数量
do_task[TASK_ACTION.DEAD_SOLDIER] = function(self, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, con_num, real_num)
    return true
end

--派遣驻守英雄
do_task[TASK_ACTION.HERO_STATION] = function(self, task_data, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(self, task_data, 1, real_num)
    return true
end



