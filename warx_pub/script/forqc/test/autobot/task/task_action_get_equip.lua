local GetEquip = {}

function GetEquip:onStart()
    self.player.eventEquipAdd:add(newFunctor(self, self._check))
end

function GetEquip:onStop()
    self.player.eventEquipAdd:del(newFunctor(self, self._check))
end

function GetEquip:onProcess(task_data, grade, num)
    self.grade = grade
    self.num = num

    self:_check()
end

function GetEquip:_check()
    local num = 0
    for k, v in pairs(self.player._equip) do
        local prop = resmng.prop_equip[v.propid]
        if self.grade <= prop.Class then
            num = num + 1
        end
    end
    if num >= self.num then
        self:_finishTask()
    end
end

return makeTaskActionHandler(TASK_ACTION.GET_EQUIP, GetEquip)

