local ChoreCure = {}

function ChoreCure:init(player)
    self.player = player

    self:_start()
end

function ChoreCure:uninit()
    self:_stop()
end

function ChoreCure:_isCuring()
    return nil ~= next(self.player.cures)
end

function ChoreCure:_hasFreeHospital()
    local class = BUILD_CLASS.FUNCTION
    local mode = BUILD_FUNCTION_MODE.HOSPITAL
    local max_seq = (BUILD_MAX_NUM[class] and BUILD_MAX_NUM[class][mode]) or 1
    local player = self.player
    for i = 1, max_seq do
        local idx = class * 10000 + mode * 100 + i 
        local build = player:get_build_by_idx(idx)
        if build then
            if build.state == BUILD_STATE.WAIT then
                return true
            end
        end
    end
end

local Watching = makeState({})
function Watching:onEnter()
    if self.host:_isCuring() then
        self:translate("Cure")
        return
    end

    self.host.player.eventHurtsUpdated:add(newFunctor(self, self._checkHurts))
    self:_checkHurts()
end

function Watching:onExit()
    self.host.player.eventHurtsUpdated:del(newFunctor(self, self._checkHurts))
end

function Watching:_checkHurts()
    local count = 0
    for k, v in pairs(self.host.player.hurts or {}) do
        count = count + v
    end
    if count > 0 then
        self:translate("TakeAction")
    end
end

local TakeAction = makeState({})
function TakeAction:onEnter()
    if self.host:_isCuring() then
        self:translate("Cure")
        return
    end
    if not self.host:_hasFreeHospital() then
        self:translate("Upgrading")
        return
    end
    -- TODO：资源是否足够未判定
    INFO("[Autobot|Cure|%d] The treatment is going to carry.", self.host.player.pid)
    Rpc:cure(self.host.player, self.host.player.hurts, 0)
    self.host.player:sync(function()
        if self.curing then
            self:translate("Cure")
        else
            self:translate("Watching")
        end
    end)
    self.host.player:addRpcErrorHandler("cure", newFunctor(self, self._onErrorHandler))
end

function TakeAction:onExit()
    self.host.player:delRpcErrorHandler("cure", newFunctor(self, self._onErrorHandler))
    self.curing = nil
end

function TakeAction:_onErrorHandler(code, reason)
    if code == resmng.E_OK then
        self.curing = true
    end
end

local Cure = makeState({})
function Cure:onEnter()
    INFO("[Autobot|Cure|%d] The hurts army is been treating", self.host.player.pid)
    self.host.player.eventCuresUpdated:add(newFunctor(self, self._onCuresUpdated))
end

function Cure:onExit()
    self.host.player.eventCuresUpdated:del(newFunctor(self, self._onCuresUpdated))
end

function Cure:_onCuresUpdated()
    if not self.host:_isCuring() then
        self:translate("Watching")
    end
end

local Upgrading = makeState({})
function Upgrading:onEnter()
    INFO("[Autobot|Cure|%d] All hospital is upgrading", self.host.player.pid)
    self.host.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
end

function Upgrading:onExit()
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
end

function Upgrading:_onBuildUpdated(player, build)
    local prop = resmng.prop_build[build.propid]
    if BUILD_CLASS.FUNCTION ~= prop.Class or BUILD_FUNCTION_MODE.HOSPITAL ~= prop.Mode then
        return
    end
    if BUILD_STATE.WAIT == build.state then
        self:translate("Watching")
    end
end

function ChoreCure:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("Watching", Watching, true)
    runner:addState("TakeAction", TakeAction)
    runner:addState("Cure", Cure)
    runner:addState("Upgrading", Upgrading)

    self.runner = runner
    runner:start()
end

function ChoreCure:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeChoreClass("Cure", ChoreCure)

