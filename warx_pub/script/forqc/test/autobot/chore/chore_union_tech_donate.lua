local ChoreUnionTechDonate = {}

local DONATE_REST_TIME = 1
local BOOT_TIME = 60

function ChoreUnionTechDonate:init(player)
    self.player = player

    player.eventUnionChanged:add(newFunctor(self, self._onUnionChanged))

    if nil ~= player.union then
        --self:_start()
    end
end

function ChoreUnionTechDonate:uninit()
    self.player.eventUnionChanged:del(newFunctor(self, self._onUnionChanged))
    self:_stop()
end

function ChoreUnionTechDonate:_onUnionChanged(player, uid)
    if 0 == uid then
        self:_stop()
    else
        self:_start()
    end
end

local Starter = makeState({})
function Starter:onEnter()
    self.func = self.func or function() self:translate("LoadTech") end
    local wait_time = math.random(math.floor(BOOT_TIME/2), BOOT_TIME)
    self.timer_id = AutobotTimer:addTimer(self.func, wait_time)
end

function Starter:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

local LoadTech = makeState({})
function LoadTech:onEnter()
    self.host.player.eventUnionLoaded:add(newFunctor(self, self._onUnionLoaded))
    Rpc:union_load(self.host.player, "tech")
end

function LoadTech:onExit()
    self.host.player.eventUnionLoaded:del(newFunctor(self, self._onUnionLoaded))
end

function LoadTech:_onUnionLoaded(player, what)
    if "tech" ~= what then
        return
    end
    self:translate("LoadDonate")
end

local LoadDonate = makeState({})
function LoadDonate:onEnter()
    self.host.player.eventUnionLoaded:add(newFunctor(self, self._onUnionLoaded))
    Rpc:union_load(self.host.player, "donate")
end

function LoadDonate:onExit()
    self.host.player.eventUnionLoaded:del(newFunctor(self, self._onUnionLoaded))
end

function LoadDonate:_onUnionLoaded(player, what)
    if "donate" ~= what then
        return
    end
    if 1 == self.host.player.donate.flag then
        self:translate("Exhausted")
    else
        self:translate("LoadTechInfo")
    end
end

local LoadTechInfo = makeState({})
function LoadTechInfo:onEnter()
    local techs = self.host.player:getDonatableTechs()
    local index = math.random(#techs)
    local tech_idx = techs[index]
    self.host.tech_idx = tech_idx
    Rpc:union_tech_info(self.host.player, tech_idx)
    self.host.player.eventUnionTechInfo:add(newFunctor(self, self._onTechInfo))
end

function LoadTechInfo:onExit()
    self.host.player.eventUnionTechInfo:del(newFunctor(self, self._onTechInfo))
end

function LoadTechInfo:_onTechInfo(player, tech)
    if tech.idx ~= self.host.tech_idx then
        return
    end
    self:translate("Donate")
end

local Donate = makeState({})
function Donate:onEnter()
    self.host.player:addRpcErrorHandler("union_donate", newFunctor(self, self._onDonate))

    if 1 == self.host.player.donate.flag then
        self:translate("Exhausted")
    else
        local tech = self.host.player:getTech(self.host.tech_idx)
        if nil == tech then
            WARN("[Autobot|UnionTechDonate|%d] tech %d not exist.", self.host.player.pid, self.host.tech_idx)
            self:translate("LoadTechInfo")
            return
        end
        local next_prop = resmng.prop_union_tech[tech.id + 1]
        if nil == next_prop or tech.exp >= next_prop.Exp * next_prop.Star then
            INFO("[Autobot|UnionTechDonate|%d] tech %d is full of exp.", self.host.player.pid, self.host.tech_idx)
            self:translate("LoadTechInfo")
            return
        end
        local donate_mode = resmng.TECH_DONATE_TYPE.PRIMARY
        -- TODO: 资源判断与模式选择
        --for k, v in pairs(tech.donate) do
        --end
        Rpc:union_donate(self.host.player, self.host.tech_idx, donate_mode)
        INFO("[Autobot|UnionTechDonate|%d] donate tech %d|%d", self.host.player.pid, self.host.tech_idx, donate_mode)
    end
end

function Donate:onExit()
    self.host.player:delRpcErrorHandler("union_donate", newFunctor(self, self._onDonate))
end

function Donate:_onDonate(code, reason)
    if code == resmng.E_OK then
        self:translate("Rest")
    else
        WARN("[Autobot|UnionTechDonate|%d] donate failed.", self.host.player.pid)
    end
end

local Rest = makeState({})
function Rest:onEnter()
    self.func = self.func or function() self:translate("Donate") end
    self.timer_id = AutobotTimer:addTimer(self.func, DONATE_REST_TIME)
end

function Rest:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

local Exhausted = makeState({})
function Exhausted:onEnter()
    self.func = self.func or function() self:translate("Starter") end

    if 1 ~= self.host.player.donate.flag then
        self:translate("Starter")
        return
    end
    local wait_time = 1
    if self.host.player.donate.tmOver > gTime then
        wait_time = self.host.player.donate.tmOver - gTime
    end
    self.timer_id = AutobotTimer:addTimer(self.func, wait_time)
    INFO("[Autobot|UnionTechDonate|%d] donate exhausted, wait %d seconds", self.host.player.pid, wait_time)
end

function Exhausted:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function ChoreUnionTechDonate:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("Starter", Starter, true)
    runner:addState("LoadTech", LoadTech)
    runner:addState("LoadDonate", LoadDonate)
    runner:addState("LoadTechInfo", LoadTechInfo)
    runner:addState("Donate", Donate)
    runner:addState("Rest", Rest)
    runner:addState("Exhausted", Exhausted)

    self.runner = runner
    runner:start()
end

function ChoreUnionTechDonate:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeChoreClass("UnionTechDonate", ChoreUnionTechDonate)

