local TroopTakeAction = {}

function TroopTakeAction:onInit()
end

function TroopTakeAction:onEnter()
    while true do
        -- 获取行军线数据
        local job = self.host:getTroopJob()
        if nil == job then
            self:_standBy()
            return
        end
        -- take action
        local func = TroopTakeAction[job.action.name]
        if func then
            INFO("[Autobot|TroopTakeAction%d] handle troop action: %s.", self.host.player.pid, job.action.name)
            if func(self, unpack(job.action.params)) then
                self.fsm:translate("Wait")
                break
            else
                -- 执行失败时该处不直接重新加回到 troop_manager 里
                -- 应该由对应的 Action 监听相关事件完成后再重新添加到 troop_manager
            end
        else
            INFO("[Autobot|TroopTakeAction%d] Not implemented troop action: %s.", self.host.player.pid, job.action.name)
        end
    end
end

function TroopTakeAction:onExit()
end

function TroopTakeAction:_standBy()
    self.fsm:translate("Idle")
end

function TroopTakeAction:AttackLevelMonster(con_type, con_level)
    INFO("[Autobot|TroopAction|AttackLevelMonster|%d] monster info: %d|%d", self.host.player.pid, con_type, con_level)

    -- TODO: 条件判定
    if self.host.player.sinew < 5 then
        -- TODO: 若是必须杀的怪，是则创建体力值监听体力恢复事件并重新加入
        return false
    end

    local executor = AttackLevelMonster.create(self.host.player, con_type, con_level)
    executor:start()

    return true
end

function TroopTakeAction:AttackSpecialMonster(task_id, monster_id)
    local player = self.host.player
    local armys = {}
    local count = player:get_val("CountSoldier")
    for id, num in pairs(player._arm) do
        if num < count then
            armys[id] = num
            count = count - num
        else
            armys[id] = count
            count = 0
            break
        end
    end
    INFO("[Autobot|TroopAction|AttackSpecialMonster|%d] monster info: %d|%d", self.host.player.pid, task_id, monster_id)
    Rpc:siege_task_npc(player, task_id, player.eid, player.x + 10, player.y + 10, {live_soldier = armys})

    return true
end

return makeState(TroopTakeAction)

