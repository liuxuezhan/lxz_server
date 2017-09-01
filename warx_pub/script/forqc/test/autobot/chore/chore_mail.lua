local ChoreMail = {}

local INTERVAL = config.Autobot.ReadMailInterval or 2

function ChoreMail:init(player)
    self.player = player
    self.unfetched_mails = {}
    self.unread_mails = {}
    self.eventReceivedMail = newEventHandler()
    player.eventAllMailLoaded:add(newFunctor(self, self._onAllMailLoaded))
    player.eventMailLoad:add(newFunctor(self, self._onMailLoad))
    player.eventNewMail:add(newFunctor(self, self._onNewMail))

    Rpc:mail_load(player, 0)
end

function ChoreMail:uninit()
    self:_stop()
    player.eventAllMailLoaded:del(newFunctor(self, self._onAllMailLoaded))
    player.eventMailLoad:del(newFunctor(self, self._onMailLoad))
    player.eventNewMail:del(newFunctor(self, self._onNewMail))
end

function ChoreMail:_onAllMailLoaded()
    self:_start()
end

function ChoreMail:_onMailLoad(player, mail)
    if 0 == mail.tm_fetch and 0 ~= mail.its then
        self.unfetched_mails[mail._id] = mail
        self.eventReceivedMail(mail)
    elseif 0 == mail.tm_read then
        self.unread_mails[mail._id] = mail
        self.eventReceivedMail(mail)
    end
end

function ChoreMail:_onNewMail(player, mail)
    if 0 == mail.tm_fetch and 0 ~= mail.its then
        self.unfetched_mails[mail._id] = mail
        self.eventReceivedMail(mail)
    elseif 0 == mail.tm_read then
        self.unread_mails[mail._id] = mail
        self.eventReceivedMail(mail)
    end
end

local Watching = makeState({})
function Watching:onInit()
    self.recv_mail = function() self:translate("Ready") end
end

function Watching:onEnter()
    self.host.eventReceivedMail:add(self.recv_mail)
end

function Watching:onExit()
    self.host.eventReceivedMail:del(self.recv_mail)
end

local Ready = makeState({})
function Ready:onInit()
    self.timer_func = newFunctor(self, self._onTimer)
end

function Ready:onEnter()
    self.timer_id = AutobotTimer:addTimer(self.timer_func, INTERVAL)
end

function Ready:onExit()
    AutobotTimer:delTimer(self.timer_id)
end

function Ready:_onTimer()
    if next(self.host.unfetched_mails) then
        self:translate("Fetch")
    elseif next(self.host.unread_mails) then
        self:translate("Read")
    else
        self:translate("Watching")
    end
end

local Fetch = makeState({})
function Fetch:onInit()
    self.fetch_func = newFunctor(self, self._onFetchResponse)
    self.read_func = newFunctor(self, self._onReadMail)
end
function Fetch:onEnter()
    local sns = {}
    for k, v in pairs(self.host.unfetched_mails) do
        if v.class ~= MAIL_CLASS.SYSTEM or v.mode ~= MAIL_SYSTEM_MODE.NORMAL then
            INFO("[Autobot|Mail|%d] Fetching attachment of incorrect mail %s|%d|%d", self.host.player.pid, v._id, v.class, v.mode)
        end
        table.insert(sns, v._id)
    end
    if #sns > 0 then
        INFO("[Autobot|Mail|%d] fetch attachment from %d mails", self.host.player.pid, #sns)
        Rpc:mail_fetch_by_sn(self.host.player, sns)
        self.host.player.eventMailFetchResponse:add(self.fetch_func)
    else
        self:_readMail()
    end
end

function Fetch:onExit()
    self.host.player.eventMailFetchResponse:del(self.fetch_func)
    self.host.player:delRpcErrorHandler("mail_read_by_class", self.read_func)
end

function Fetch:_onFetchResponse(player, sns)
    for k, v in pairs(sns) do
        self.host.unfetched_mails[v] = nil
    end
    self:_readMail()
end

function Fetch:_readMail()
    Rpc:mail_read_by_class(self.host.player, MAIL_CLASS.SYSTEM, -1, -1)
    self.host.player:addRpcErrorHandler("mail_read_by_class", self.read_func)
end

function Fetch:_onReadMail()
    for k, v in pairs(self.host.unread_mails) do
        if v.class == MAIL_CLASS.SYSTEM then
            INFO("[Autobot|Mail|%d] system mail %d has been read.", self.host.player.pid, v.idx)
            self.host.unread_mails[v._id] = nil
        end
    end
    self:translate("Ready")
end

local Read = makeState({})
function Read:onInit()
    self.read_func = newFunctor(self, self._onReadMail)
end

function Read:onEnter()
    local id, mail = next(self.host.unread_mails)
    if nil == id then
        self:translate("Ready")
        return
    end
    local sns = {}
    if mail.class == MAIL_CLASS.REPORT then
        for k, v in pairs(self.host.unread_mails) do
            if mail.class == v.class and mail.mode == v.mode then
                table.insert(sns, v._id)
            end
        end
    else
        table.insert(sns, id)
    end
    if #sns > 0 then
        INFO("[Autobot|Mail|%d] read %d mails", self.host.player.pid, #sns)
        Rpc:mail_read_by_sn(self.host.player, sns)
        self.sns = sns
        self.host.player:addRpcErrorHandler("mail_read_by_sn", self.read_func)
    else
        self:translate("Ready")
    end
end

function Read:onExit()
    self.host.player:delRpcErrorHandler("mail_read_by_sn", self.read_func)
    self.sns = nil
end

function Read:_onReadMail(code, idx)
    for k, v in pairs(self.sns) do
        if nil == self.host.unread_mails[v] then
            self.sns[k] = nil
            INFO("[Autobot|Mail|%d] non-exist mail %d.", self.host.player.pid, idx)
        elseif self.host.unread_mails[v].idx == idx then
            INFO("[Autobot|Mail|%d] mail %d has been read.", self.host.player.pid, idx)
            self.host.unread_mails[v] = nil
            self.sns[k] = nil
            break
        end
    end
    if nil == next(self.sns) then
        INFO("[Autobot|Mail|%d] All mails has been read.", self.host.player.pid)
        self:translate("Ready")
    end
end

function ChoreMail:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("Watching", Watching)
    runner:addState("Ready", Ready, true)
    runner:addState("Fetch", Fetch)
    runner:addState("Read", Read)

    self.runner = runner
    runner:start()
end

function ChoreMail:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeChoreClass("Mail", ChoreMail)

