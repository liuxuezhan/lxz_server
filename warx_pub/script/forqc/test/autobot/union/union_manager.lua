local UnionManager = {}

UnionManager.unions = {}

function UnionManager:init()
end

function UnionManager:getUnion(uid)
    local union = self.unions[uid]
    if nil ~= union then
        return union
    end
    local union_data = _us[uid]
    if nil == union_data then
        return
    end
    union = Union.create(union_data)
    self.unions[uid] = union

    return union
end

return UnionManager

