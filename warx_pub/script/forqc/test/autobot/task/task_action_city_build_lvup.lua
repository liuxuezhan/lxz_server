local CityBuildLevelUp = {}

function CityBuildLevelUp:onStart()
    self.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
    self.player.eventNewBuild:add(newFunctor(self, self._onNewBuild))
end

function CityBuildLevelUp:onStop()
    self.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
    self.player.eventNewBuild:del(newFunctor(self, self._onNewBuild))
end

function CityBuildLevelUp:onProcess(task_data, build_id, count, level)
    local prop = getTaskProp(task_data)
    self.build_id = build_id
    self.count = count
    self.level = level

    self:_checkBuilding()
end

function CityBuildLevelUp:_checkBuilding()
    if self.count > 1 then
        local count = 0
        for k, v1 in pairs(self.player._build or {}) do
            local prop = resmng.prop_build[v1.propid]
            local specific = prop.Specific
            if specific == BUILD_FUNCTION_MODE.TUTTER_RIGHT then
                specific = BUILD_FUNCTION_MODE.TUTTER_LEFT
            end
            if specific == self.build_id then
                if prop.Lv >= self.level then
                    count = count + 1
                end
            end
        end
        if count >= self.count then
            self:_finishTask()
        end
    else
        for k, v in pairs(self.player._build or {}) do
            local prop = resmng.prop_build[v.propid]
            local specific = prop.Specific
            if specific == BUILD_FUNCTION_MODE.TUTTER_RIGHT then
                specific = BUILD_FUNCTION_MODE.TUTTER_LEFT
            end
            if specific == self.build_id then
                if prop.Lv >= self.level then
                    self:_finishTask()
                    break
                end
            end
        end
    end
end

function CityBuildLevelUp:_onBuildUpdated(player, build)
    local prop = resmng.prop_build[build.propid]
    if prop.Specific ~= self.build_id then
        return
    end
    if prop.Lv < self.level then
        return
    end
    self:_checkBuilding()
end

function CityBuildLevelUp:_onNewBuild(player, build)
    local prop = resmng.prop_build[build.propid]
    if prop.Specific ~= self.build_id then
        return
    end
    if prop.Lv < self.level then
        return
    end
    self:_checkBuilding()
end

return makeTaskActionHandler(TASK_ACTION.CITY_BUILD_LEVEL_UP, CityBuildLevelUp)

