module("player_t")

function calc_left_award_time(self)
    local award_num = #resmng.prop_online_award
    if award_num <= self.online_award_num then
        return -1
    end

    local prop = resmng.prop_online_award[self.online_award_num + 1]
    local time = self.online_award_time + prop.Time - gTime
    if time > 0 then
        return time
    else
        return 0
    end
end

function get_online_award_next_time(self)  
    local award_num = #resmng.prop_online_award
    if award_num <= self.online_award_num then
        return -1
    end

    local prop = resmng.prop_online_award[self.online_award_num + 1]
    if prop == nil then
        return
    end
    return (self.online_award_time + prop.Time)
end

function is_online_award_end(self) 
    local award_num = #resmng.prop_online_award
    if award_num <= self.online_award_num then
        return true
    end
    return false
end

function get_online_award(self)
    if self:is_online_award_end() == true then 
        return false 
    end
    
    local left_time = self:calc_left_award_time()
    if left_time ~= 0 then 
        return false 
    end

    self.online_award_num = self.online_award_num + 1
    self.online_award_time = gTime
    local prop = resmng.prop_online_award[self.online_award_num]
    self:add_bonus(prop.BonusPolicy, prop.Bonus, VALUE_CHANGE_REASON.REASON_ONLINE_AWARD)
    self:refresh_online_award()

    local ship = self:get_shipyard()
    if ship ~= nil then
        ship:set_extra("next_time", self:get_online_award_next_time())
        ship:set_extra("prev_time", gTime )
    end
    self:add_count( resmng.ACH_COUNT_DAILY_REWARD, 1 )
    --任务
    task_logic_t.process_task(self, TASK_ACTION.DAY_AWARD, 1)
end

function refresh_online_award(self)
   if self.online_award_on_day_pass == 0 then
       return
   end

   self.online_award_time = gTime
   self.online_award_num = 0
   self.online_award_on_day_pass = 0
end

function on_day_pass_online_award(self)
   self.online_award_on_day_pass = 1 
end


function open_online_award(self)
    self.online_award_time = gTime
    self.online_award_num = 0
    self.online_award_on_day_pass = 0
    --local ship = self:get_shipyard()
    --if ship ~= nil then
    --    ship.extra.next_time = self:get_online_award_next_time()
    --end
end



