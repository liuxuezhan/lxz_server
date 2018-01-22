local ChoreLevelGift = {}
local LevelGift = config.Autobot.LevelGift or {}

function ChoreLevelGift:init(player)
    self.player = player
    self.claim_flag = {}

    self.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))

    self:_claim_gift(player:get_build(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.CASTLE))
end

function ChoreLevelGift:uninit()
    self.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
end

function ChoreLevelGift:_onBuildUpdated(player, build)
    self:_claim_gift(build)
end

function ChoreLevelGift:_claim_gift(build)
    local prop = resmng.prop_build[build.propid]
    if not prop then
        return
    end
    if BUILD_CLASS.FUNCTION ~= prop.Class or BUILD_FUNCTION_MODE.CASTLE ~= prop.Mode then
        return
    end
    if not LevelGift[prop.Lv] then
        return
    end
    if self.claim_flag[prop.Lv] then
        return
    end
    Rpc[LevelGift[prop.Lv]](Rpc, self.player)
end

return makeChoreClass("ChoreLevelGift", ChoreLevelGift)

