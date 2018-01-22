local StudyTech = {}

function StudyTech:onStart()
    self.player.tech_manager.eventTechUpdated:add(newFunctor(self, self._onTechUpdated))
end

function StudyTech:onStop()
    self.player.tech_manager.eventTechUpdated:del(newFunctor(self, self._onTechUpdated))
end

function StudyTech:onProcess(task_data, tech_id, level)
    self.tech_id = tech_id
    self.level = level
    local prop = resmng.prop_tech[tech_id]
    self.tech_type = prop.Class * 1000 + prop.Mode

    self:_checkTech()
end

function StudyTech:_checkTech()
    local tech_lv = self.player.tech_manager:getLearnedTechLevel(self.tech_type)
    if nil == tech_lv or tech_lv < self.level then
        return
    end
    self:_finishTask()
end

function StudyTech:_onTechUpdated(player, tech_id)
    self:_checkTech()
end

return makeTaskActionHandler(TASK_ACTION.STUDY_TECH, StudyTech)

