--新手军团
module(..., package.seeall)
_id = 0 --序号,外部引用

function new()--创建新手军团
    _id = _id + 1
    local id = 1000 + _id
    local data = {
        uid=id,_id=id,name=name,alias=alias,level=1,language=10,credit=0,
        membercount=0,note_in="",note_out="",invites = {},new_union_sn=_id
    }
    local union = union_t.new(data)

    unionmng.add_union(union)
    gPendingSave.union_log[id] = {_id=id}

    union_mission.get(id)
    return union
end

function add(p)--加入新手军团
    for _, u in pairs(unionmng.get_all()) do
        if u:is_new() and u.membercount < u:get_memberlimit() then
            if u:add_member(p) then return end
        end
    end
    local u = new_union.new()
    u:add_member(p)
end

function update(p)--玩家城堡等级改变处理
    local build = p:get_build(1)
    local node = resmng.get_conf("prop_build", build.propid)
    local u = unionmng.get_union(p:get_uid())
    if (not u )or (u and not u:is_new()) then
        return
    end

    if node.Lv > 5 then
        p:union_quit()
    elseif node.Lv > 3 then
        p:set_rank(resmng.UNION_RANK_3)
    elseif node.Lv > 2 then
        p:set_rank(resmng.UNION_RANK_2)
    end


end













