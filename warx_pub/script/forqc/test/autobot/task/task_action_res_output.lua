local ResOutput = {}

function ResOutput:onStart()
    self.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
    self.player.eventNewBuild:add(newFunctor(self, self._onBuildUpdated))
end

function ResOutput:onStop()
    self.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
    self.player.eventNewBuild:del(newFunctor(self, self._onBuildUpdated))
end

function ResOutput:onProcess(task_data, mode, value)
    self.mode = mode
    self.value = value

    self:_check()
end

function ResOutput:_check()
    local num = 0
    for k, v in pairs(self.player._build) do
        local prop = resmng.prop_build[v.propid]
        if prop.Class == BUILD_CLASS.RESOURCE and prop.Mode == self.mode then
            num = num + v.extra.speed or 0
        end
    end

    if num >= self.value then
        self:_finishTask()
    end
end

function ResOutput:_onBuildUpdated(player, build)
    local prop = resmng.prop_build[build.propid]
    if prop.Class == BUILD_CLASS.RESOURCE and prop.Mode == self.mode then
        self:_check()
    end
end

return makeTaskActionHandler(TASK_ACTION.RES_OUTPUT, ResOutput)

