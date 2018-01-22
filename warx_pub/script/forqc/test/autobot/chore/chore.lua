local Chore = {}

local INSTANT_CHORES = 
{
    "_doSignIn",            -- 签到
    "_claimWeekAward",      -- 七日登录
    --"_claimMonthlyCard",    -- 月卡领取
}
local INSTANT_INTERVAL = config.Autobot.ChoreInstantInterval or 2

local CHORES = {}
function makeChoreClass(name, class)
    local creator = {}
    creator.__index = creator
    creator.create = function(...)
        local instance = setmetatable({}, class)
        instance:init(...)
        return instance
    end

    class.__index = class
    class.name = name

    table.insert(CHORES, class)
    return setmetatable(class, creator)
end

function Chore:onInit()
end

function Chore:onEnter()
    self.chores = {}

    local player = self.host
    for k, v in ipairs(CHORES) do
        assert(nil == self.chores[v.name], string.format("exist chore: %s", v.name))
        local chore = v.create(player)
        self.chores[v.name] = chore
    end

    self:_startInstantChroes()
end

function Chore:onExit()
    for k, v in pairs(self.chores) do
        INFO("[Autobot|Chore|%d] uninit chore : %s", self.host.pid, k)
        v:uninit()
    end
    self:_stopInstantChores()
end

function Chore:_startInstantChroes()
    self.instant_index = 0
    self.instant_id = AutobotTimer:addPeriodicTimer(newFunctor(self, Chore._doInstantChore), INSTANT_INTERVAL)
end

function Chore:_stopInstantChores()
    if self.instant_id then
        AutobotTimer:delPeriodicTimer(self.instant_id)
        self.instant_id = nil
    end
end

function Chore:_doInstantChore()
    self.instant_index = self.instant_index + 1
    if self.instant_index > #INSTANT_CHORES then
        self:_stopInstantChores()
        return
    end
    local func_name = INSTANT_CHORES[self.instant_index]
    if nil ~= self[func_name] then
        self[func_name](self)
    else
        INFO("[Autobot|Chore|%d] _doInstantChore don't find func %s.", self.host.pid, func_name)
    end
end

-- 签到
function Chore:_doSignIn()
    INFO("[Autobot|Chore|%d] sign in", self.host.pid)
    Rpc:month_award_get_award(self.host)
end

function Chore:_claimWeekAward()
    if self.host.qiri_num >= 7 then
        INFO("[Autobot|Chore|%d] All weekly award has been claimed.", self.host.pid)
        return
    end
    local diff_days = get_diff_days(gTime, self.host.qiri_time)
    if diff_days <= 0 then
        INFO("[Autobot|Chore|%d] Today's award has been claimed.", self.host.pid)
        return
    end
    INFO("[Autobot|Chore|%d] Claiming week award.", self.host.pid)
    Rpc:qiri_get_award(self.host)
end

function Chore:_claimMonthlyCard()
    local cur_day = get_days(gTime)
    if cur_day > self.host.tm_yueka_end then
        --INFO("[Autobot|Chore|%d] Month Card is out of time(%d > %d).", self.host.pid, cur_day, self.host.tm_yueka_end)
        --return
        Rpc:buy_yueka(self.host)
    end
    if cur_day <= self.host.tm_yueka_cur then
        INFO("[Autobot|Chore|%d] Month Card has been claimed.", self.host.pid)
        return
    end
    INFO("[Autobot|Chore|%d] Claiming month-card award.", self.host.pid)
    Rpc:get_yueka_award(self.host)
end

return makeState(Chore)

