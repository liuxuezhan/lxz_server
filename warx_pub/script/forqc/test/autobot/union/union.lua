local Union = {}

function Union:init(data)
    self.data = data
    self.uid = data.uid
end

function Union:onUnionLoaded(player, what, union)
end

function Union:get_build(idx)
    local udata = _us[self.uid]
    local build = udata.build[idx]

    return build
end

return makeClass(Union, makeDataIndex(Union, "data"))

