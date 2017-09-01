local JoinUnion_CreateUnion = {}

local MAX_WAIT_TIME = 5

local alias_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local alias_count = string.len(alias_chars)

local random = math.random

function _drawChar()
    return string.byte(alias_chars, random(alias_count))
end

function _genAlias()
    return string.format("%c%c%c", _drawChar(), _drawChar(), _drawChar())
end

function _genName(leader)
    return string.format("Bot%d", leader.pid)
end

local gods = {
    resmng.UNION_GOD_1000,
    resmng.UNION_GOD_2000,
    resmng.UNION_GOD_3000,
    resmng.UNION_GOD_4000,
}

function _genGod()
    return gods[math.random(#gods)]
end

function _selectLanguage()
    return resmng.LANGUAGE_DEF_40
end

function JoinUnion_CreateUnion:onEnter()
    INFO("[Autobot|JoinUnion|%d] Creating union.", self.host.player.pid)
    Rpc:union_create(self.host.player, _genName(self.host.player), _genAlias(), _selectLanguage(), _genGod())

    self.host.player:addRpcErrorHandler("union_create", newFunctor(self, self._onCreateError))
    self.timer_id = AutobotTimer:addTimer(newFunctor(self, self._onTimeout), MAX_WAIT_TIME)
end

function JoinUnion_CreateUnion:onExit()
    self.host.player:delRpcErrorHandler("union_create", newFunctor(self, self._onCreateError))
    AutobotTimer:delTimer(self.timer_id)
end

function JoinUnion_CreateUnion:_onCreateError(code, reason)
    self:translate("GetUnions")
end

function JoinUnion_CreateUnion:_onTimeout()
    self:translate("GetUnions")
end

return makeState(JoinUnion_CreateUnion)

