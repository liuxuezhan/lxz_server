module("act_mng", package.seeall)

act_state = act_state  or 0
start_act_tm = start_act_tm or 0

function load_act_state()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = "act_mng"})
    if not info then
        info = {_id = "act_mng"}
        db.status:insert(info)
    end
    if info.act_state then
        act_state = info.act_state
        start_act_tm = info.start_act_tm
    else
        init_act()
        try_open_act()
    end

end

function init_act()
    if act_state ~= 0 then
        return
    end

    local now = os.date("*t", gTime)
    if now.hour < 6 then
        start_act_tm = get_zero_tm(gTime)
    else
        start_act_tm = get_zero_tm(gTime) + 24 * 3600
    end
    act_state = 1
    gPendingSave.status["act_mng"].act_state = act_state
    gPendingSave.status["act_mng"].start_act_tm = start_act_tm
end

function try_open_act()
    npc_city.try_start_tw()
    monster_city.try_active_mc()
    lost_temple.try_start_lt()
    king_city.try_unlock_kw()
end

function kaifu_act()
    act_state = 0
    start_act_tm = 0
    gPendingDelete.status["act_mng"] = 1
end
