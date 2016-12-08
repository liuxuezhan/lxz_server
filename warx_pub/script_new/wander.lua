module(..., package.seeall)
_d = {}
module_class(..., 
{
    _id = 0,
    propid = 0,
    x = 0,
    y = 0,
})

function load()
    local db = dbmng:getOne()
    local info = db.wander:find({})
    while info:hasNext() do
        local e = info:next()
        if not _d[e.propid] then _d[e.propid] = {data={},}  end
        _d[e.propid].data[e.eid]  =  e  
        gEtys[ e.eid ] = e
        etypipe.add(e)
    end
    create()
end

function create()
    for _, v in pairs(resmng.prop_world_unit or {}) do
        if v.Class == EidType.Wander then
            if not _d[v.ID] then _d[v.ID] = {data={},}  end
            local objs = _d[v.ID].data 
            local num = v.Count - get_table_valid_count(objs)
            if num > 0 then
                for i = 1,num do
                    local x, y = c_get_pos_by_lv(v.Lv,v.Size,v.Size)
                    local eid = get_eid(EidType.Wander)
                    local e = new({_id = eid, eid=eid, size = v.Size, propid=v.ID, x = x, y = y, })
                    objs[e.eid] = e
                    gEtys[ e.eid ] = e
                    etypipe.add(e)
                end
            end
        end
    end
end
