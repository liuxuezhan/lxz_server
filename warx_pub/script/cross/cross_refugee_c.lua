module("cross_refugee_c", package.seeall)

act_state = act_state or 0

function cast_refugee_st()
    local pack = {}
    local act = {}
    act.state = act_state
    pack[ACT_NAME.REFUGEE] = act

    cross_mng_c.send_to_all_group("cross_act_st_cast", pack)
end

function cast_refugee_end()
    cross_mng_c.send_to_all_group("refugee_end")
end

function load_data()
    local db = dbmng:getOne()

    local info = db.status:findOne({_id = "cross_act"})
    if not info then
        info = {_id = "cross_act"}
        db.status:insert(info)
    end
    act_state = info.act_state  or 0
end

function cross_refugee_start()
    act_state = CROSS_STATE.FIGHT
    gPendingSave.status["cross_act"].refugee_state = act_state
    cast_refugee_st()
end

function cross_refugee_end()
    act_state = CROSS_STATE.PEACE
    gPendingSave.status["cross_act"].refugee_state = act_state
    cast_refugee_end()
end

