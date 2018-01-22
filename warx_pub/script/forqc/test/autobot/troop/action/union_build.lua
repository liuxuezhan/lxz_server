local UnionBuild = {}

function UnionBuild:init(player, build_idx)
    self.player = player
    self.build_idx = build_idx
end

function UnionBuild:start()
    self:_start()
end

function UnionBuild:uninit()
    self:_stop()
end

function UnionBuild:_finish()
    self:accomplish()
end

local InspectBuild = makeState({})
function InspectBuild:onEnter()
    INFO("[Autobot|UnionBuild|%d] inspect build %d", self.host.player.pid, self.host.build_idx)
    local build = self.host.player.union:get_build(self.host.build_idx)
    if nil == build or build.state ~= BUILD_STATE.CREATE or 0 == build.eid then
        INFO("[Autobot|UnionBuild|%d] no need to build building %d", self.host.player.pid, self.host.build_idx)
        self.host:_finish()
        return
    end
    Rpc:get_eye_info(self.host.player, build.eid)
    self.build_eid = build.eid
    self.host.player.eventEyeInfo:add(newFunctor(self, self._onEyeInfo))
end

function InspectBuild:onExit()
    self.host.player.eventEyeInfo:del(newFunctor(self, self._onEyeInfo))
end

function InspectBuild:_onEyeInfo(player, eid, info)
    if eid ~= self.build_eid then
        return
    end
    INFO("[Autobot|UnionBuild|%d] inspect result %d", self.host.player.pid, info.dp.state)
    if info.dp.state ~= BUILD_STATE.CREATE then
        self.host:_finish()
        return
    end
    self:translate("Assemble", eid, info.hold_num, info.hold_limit)
end

local Assemble = makeState({})
function Assemble:onEnter(eid, hold_num, hold_limit)
    local soldier_count = 300
    local army_count = 3000
    local min_count = 1000
    if army_count > self.host.player:get_val("CountSoldier") then
        army_count = self.host.player:get_val("CountSoldier")
    end
    if army_count > hold_limit - hold_num then
        army_count = hold_limit - hold_num
    end
    if 0 == army_count then
        INFO("[Autobot|UnionBuild|%d] Assembling work team %d|%d for building %d", self.host.player.pid, hold_num, hold_limit, eid)
        self.host:_finish()
        return
    end
    local army = {}
    local total_count = 0
    for id, num in pairs(self.host.player._arm) do
        local need_count = num < soldier_count and num or soldier_count
        army[id] = need_count
        total_count = total_count + need_count
        if total_count >= army_count then
            break
        end
    end

    if total_count < min_count then
        self:translate("LackOfSoldier")
        return
    end

    INFO("[Autobot|UnionBuild|%d] Assembling work team %d|%d for building %d", self.host.player.pid, hold_num, hold_limit, eid)
    Rpc:union_build(self.host.player, eid, {live_soldier = army})
    self.target_eid = eid
    self.host.player.eventTroopUpdated:add(newFunctor(self, self._onTroopUpdated))
end

function Assemble:onExit()
    self.host.player.eventTroopUpdated:del(newFunctor(self, self._onTroopUpdated))
end

function Assemble:_onTroopUpdated(player, troop_id, troop)
    INFO("[Autobot|UnionBuild|%d] Troop updated %s|%d", self.host.player.pid, troop.target, self.target_eid)
    if troop.target ~= self.target_eid then
        return
    end
    local base_action = math.floor(troop.action % 100)
    if base_action ~= TroopAction.UnionBuild then
        return
    end
    self:translate("March", troop_id)
end

local LackOfSoldier = makeState({})
function LackOfSoldier:onInit()
    self.army_func = function() self:translate("InspectBuild") end
end

function LackOfSoldier:onEnter()
    self.host.player.eventArmyUpdated:add(self.army_func)
end

function LackOfSoldier:onExit()
    self.host.player.eventArmyUpdated:del(self.army_func)
end


local March = makeState({})
function March:onEnter(troop_id)
    INFO("[Autobot|UnionBuild|%d] Troop %d is marching to build building", self.host.player.pid, troop_id)
    self.troop_id = troop_id
    self.host.player.eventTroopUpdated:add(newFunctor(self, self._onTroopUpdated))
    self.host.player.eventTroopDeleted:add(newFunctor(self, self._onTroopDeleted))
end

function March:onExit()
    self.host.player.eventTroopUpdated:del(newFunctor(self, self._onTroopUpdated))
    self.host.player.eventTroopDeleted:del(newFunctor(self, self._onTroopDeleted))
    self.troop_id = nil
end

function March:_onTroopUpdated(player, troop_id, troop)
    if troop_id ~= self.troop_id then
        local action = math.floor(troop.action % 100)
        local direction = math.floor(troop.action / 100)
        if direction ~= 2 or action ~= TroopAction.UnionBuild then
            return
        end
        -- 加入先前部队的troop
        self:translate("Hold", troop_id)
    else
        local direction = math.floor(troop.action / 100)
        if 3 == direction then
            -- 直接返回，修建失败
            self:translate("Back", troop_id)
        elseif 2 == direction then
            -- 驻守，是第一个进入建筑的人
            self:translate("Hold", troop_id)
        end
    end
end

function March:_onTroopDeleted(player, troop_id)
    if troop_id ~= self.troop_id then
        return
    end
    -- 不是第一个进入建筑的人
end

local Hold = makeState({})
function Hold:onEnter(troop_id)
    --self.host.player.eventUnionBuildUpdated:add(newFunctor(self, self._onUnionBuildUpdated))
    self.host.player.eventTroopUpdated:add(newFunctor(self, self._onTroopUpdated))

    INFO("[Autobot|UnionBuild|%d] Troop %d arrived building, start to work.", self.host.player.pid, troop_id)
    self.troop_id = troop_id
    self:_checkBuild()
end

function Hold:onExit()
    --self.host.player.eventUnionBuildUpdated:del(newFunctor(self, self._onUnionBuildUpdated))
    self.host.player.eventTroopUpdated:del(newFunctor(self, self._onTroopUpdated))
end

function Hold:_checkBuild()
    local build = self.host.player.union:get_build(self.host.build_idx)
    if nil == build or build.state ~= BUILD_STATE.CREATE  then
        self:translate("Recall", self.troop_id)
    end
end

function Hold:_onUnionBuildUpdated(player, build)
    --INFO("[Autobot|UnionBuild|%d] union build updated %d|%d|%d|%d.", self.host.player.pid, self.troop_id, build.state, build.idx, self.host.build_idx)
    --if build.idx == self.host.build_idx then
    --    self:_checkBuild()
    --end
end

function Hold:_onTroopUpdated(player, troop_id, troop)
    if troop._id == self.troop_id then
        -- 军团奇迹建造完成后更改为HoldDefense
        local direction = math.floor(troop.action / 100)
        local base_action = math.floor(troop.action % 100)
        if direction == 2 and base_action == TroopAction.HoldDefense then
            self:translate("Recall", self.troop_id)
        end
    else
        -- 其他军团建筑完成后，自动遣返所有部队
        local base_action = math.floor(troop.action % 100)
        if base_action ~= TroopAction.UnionBuild then
            return
        end
        local build = self.host.player.union:get_build(self.host.build_idx)
        if nil == build then
            return
        end
        if build.eid ~= troop.target then
            return
        end
        self:translate("Back", troop._id)
    end
end

local Recall = makeState({})
function Recall:onEnter(troop_id)
    INFO("[Autobot|UnionBuild|%d] The work has finished, recall troop %d", self.host.player.pid, troop_id)
    Rpc:troop_recall(self.host.player, troop_id)
    self.host.player.eventTroopUpdated:add(newFunctor(self, self._onTroopUpdated))
end

function Recall:onExit()
    self.host.player.eventTroopUpdated:del(newFunctor(self, self._onTroopUpdated))
end

function Recall:_onTroopUpdated(player, troop_id, troop)
    local base_action = math.floor(troop.action % 100)
    if base_action ~= TroopAction.HoldDefense then
        return
    end
    local build = self.host.player.union:get_build(self.host.build_idx)
    if nil == build then
        return
    end
    if build.eid ~= troop.target then
        return
    end
    self:translate("Back", troop._id)
end

local Back = makeState({})
function Back:onEnter(troop_id)
    INFO("[Autobot|UnionBuild|%d] Troop %d is returning", self.host.player.pid, troop_id)
    self.troop_id = troop_id
    self.host.player.eventTroopDeleted:add(newFunctor(self, self._onTroopDeleted))
end

function Back:onExit(troop_id)
    self.host.player.eventTroopDeleted:del(newFunctor(self, self._onTroopDeleted))
end

function Back:_onTroopDeleted(player, troop_id)
    if self.troop_id ~= troop_id then
        return
    end
    INFO("[Autobot|UnionBuild|%d] Troop %d returned", self.host.player.pid, self.troop_id)
    self.host:_finish()
end

function UnionBuild:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("InspectBuild", InspectBuild, true)
    runner:addState("Assemble", Assemble)
    runner:addState("LackOfSoldier", LackOfSoldier)
    runner:addState("March", March)
    runner:addState("Hold", Hold)
    runner:addState("Recall", Recall)
    runner:addState("Back", Back)

    self.runner = runner
    runner:start()
end

function UnionBuild:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return SiegeAction.makeClass("UnionBuild", UnionBuild, TroopAction.UnionBuild)

