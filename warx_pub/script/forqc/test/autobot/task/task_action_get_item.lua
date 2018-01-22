local GetItem = {}

function GetItem:onStart()
    self.player.eventItemUpdated:add(newFunctor(self, self._check))
end

function GetItem:onStop()
    self.player.eventItemUpdated:del(newFunctor(self, self._check))
end

function GetItem:onProcess(task_data, item_id, num)
    self.item_id = item_id
    self.num = num

    self:_check()
end

function GetItem:_check()
    local item = self.player:get_item(self.item_id)
    if nil == item then
        return
    end
    if item[3] < self.num then
        return
    end
    self:_finishTask()
end

return makeTaskActionHandler(TASK_ACTION.GET_ITEM, GetItem)

