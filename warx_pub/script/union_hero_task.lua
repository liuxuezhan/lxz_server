-- hero task muti players 
module(..., package.seeall) 

u_hero_tasks = u_hero_tasks or {}

function load()
    local db = dbmng:getOne()
    local info = db.union_hero_task:find({})
    while info:hasNext() do
        local d = info:next()
        local union = unionmng.get_union(d.uid)
        if union then
            if not union.hero_task then union.hero_task = {} end
            union.hero_task[d._id] = d
            u_hero_tasks[d._id] = d
        end
    end
end

function clear(uid)
     local union = unionmng.get_union(uid) 
     if union then
         for k, _ in pairs(union.hero_task or {}) do
              gPendingSave.union_hero_task[k] = nil
         end
     end
     union.hero_task = nil
end

function mark(data)
    local union = unionmng.get_union(data.uid)
    if not union then return false end
    if not union.hero_task then union.hero_task = {} end
    union.hero_task[data._id] = data
    if not u_hero_tasks[data._id] then
        u_hero_tasks[data._id] = data
    end
    gPendingSave.union_hero_task[data._id] = data
end

function del(data)
    local union = unionmng.get_union(data.uid)
    if not union then return false end
    if not union.hero_task then
        return
    end
    union.hero_task[data._id] = nil
    u_hero_tasks[data._id] = nil
    gPendingSave.union_hero_task[data._id] = nil
end

function get(uid, _id)
    local union = unionmng.get_union(uid)
    if not union then
        return
    end
    if not union.hero_task then union.hero_task = {} end
    return union.hero_task[_id]
end

function get_by_id(_id)
    return u_hero_task[_id]
end

