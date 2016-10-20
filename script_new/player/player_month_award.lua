module("player_t")

function month_award_check( self )
    local idx = get_diff_days( gTime, self.month_award_1st ) + 1
    if idx > 28 then 
        self.month_award_1st = gTime
        self.month_award_mark = 0
        self.month_award_count = 0
        self.month_award_round = self.month_award_round + 1
    end
end


function month_award_get_award(self)
    self:month_award_check()

    local cur = self.month_award_mark + 1
    local max = get_diff_days( gTime, self.month_award_1st ) + 1

    if cur > max then return end

    local remedy_count = 0 --补签次数
    if self:is_vip_enable() then
        local vip_prop = resmng.get_conf( "prop_vip", self.vip_lv )
        if vip_prop then
            remedy_count = self.month_award_count + (vip_prop.MonthAward or 0)
        end
    end

    local flag = false
    if get_diff_days( gTime, self.month_award_cur ) > 0 then
        self.month_award_cur = gTime
        flag = true
    elseif remedy_count > 0 then
        self.month_award_count = self.month_award_count - 1
        flag = true
    end

    if not flag then return end

    self.month_award_mark = cur
    local prop = resmng.prop_month_award[cur]
    if self.month_award_round > 1 then prop = resmng.prop_month_award[ cur + 28 ] end
    if not prop then return end

    local handle = false
    if prop.Extra then
        if self:is_vip_enable() then
            if self.vip_lv >= prop.Extra[ 1 ] then
                self:add_bonus(prop.BonusPolicy, prop.Bonus, VALUE_CHANGE_REASON.REASON_MONTH_AWARD, prop.Extra[2])
                handle = true
            end
        end
    end

    if not handle then
        self:add_bonus(prop.BonusPolicy, prop.Bonus, VALUE_CHANGE_REASON.REASON_MONTH_AWARD, 1)
    end
    --任务 
    task_logic_t.process_task(self, TASK_ACTION.MONTH_AWARD, 1)
    return cur
end

