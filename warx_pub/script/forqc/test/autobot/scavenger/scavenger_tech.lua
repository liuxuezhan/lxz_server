local ScavengerTech = {}

local TECH_PRIORITY = 500

local tech_list = {}

for k, v in pairs(resmng.prop_tech) do
    local tech_type_id = v.Class * 1000 + v.Mode
    tech_list[tech_type_id] = tech_list[tech_type_id] or {}
    tech_list[tech_type_id][v.Lv] = k
end

function ScavengerTech:onInit()
    self.added_tech = {}
end

function ScavengerTech:onEnter()
    self.host.eventTechUpdated:add(newFunctor(self, ScavengerTech._onTechUpdated))
    self.host.player.eventBuildUpdated:add(newFunctor(self, ScavengerTech._onBuildUpdated))

    self:_scanAvailableTech()
end

function ScavengerTech:onExit()
    self.host.player.eventBuildUpdated:del(newFunctor(self, ScavengerTech._onBuildUpdated))
    self.host.eventTechUpdated:del(newFunctor(self, ScavengerTech._onTechUpdated))
end

function ScavengerTech:_onTechUpdated(player, tech_id, is_new)
    self:_scanAvailableTech()
end

function ScavengerTech:_onBuildUpdated(player, build)
    local prop = resmng.prop_build[build.propid]
    if not prop then
        return
    end
    if BUILD_CLASS.FUNCTION ~= prop.Class or BUILD_FUNCTION_MODE.ACADEMY ~= prop.Mode then
        return
    end
    self:_scanAvailableTech()
end

function ScavengerTech:_scanAvailableTech()
    -- 查找可升级的科技
    local techs = {}
    for k, v in pairs(tech_list) do
        local tech_lv = self.host:getLearnedTechLevel(k)
        if tech_lv then
            -- 已有技能
            local propid = v[tech_lv + 1]
            if propid then
                -- 有下一级
                if self.host:condCheck(propid) then
                    table.insert(techs, propid)
                end
            end
        else
            -- 未学技能
            local propid = v[1]
            if propid then
                if self.host:condCheck(propid) then
                    table.insert(techs, propid)
                end
            end
        end
    end
    -- 没找到可升级的科技，则等待
    if #techs > 0 then
        for k, v in ipairs(techs) do
            self:_addTech(v)
        end
    else
        INFO("[Autobot|ScavengerTech|%d] no upgradable tech.", self.host.player.pid)
    end
end

function ScavengerTech:_addTech(propid)
    if self.added_tech[propid] then
        return
    end
    self.host:addStudyJob(propid, TECH_PRIORITY)
    self.added_tech[propid] = true
    INFO("[Autobot|ScavengerTech|%d] scavenge new available tech %d", self.host.player.pid, propid)
end

return makeState(ScavengerTech)

