module( "cross_act", package.seeall ) 

act_state = act_state or 0

refugee_state = refugee_state  or 0

tm_over = tm_over or 0

function rec_cross_act_st(act_st)
    for k, st in pairs(act_st or {}) do
        if k == ACT_NAME.CROSS_NPC then
            act_state = st.state or 0
            tm_over = st.tm_over or 0
        elseif k == ACT_NAME.REFUGEE then
            refugee.act_state = st.state or 0
            refugee_state = st.state or 0
        end
    end
end

function load_data()
    local map_id = 999
--    Rpc:callAgent(map_id, "cross_act_st_req", 1)
end

function cross_act_st_req(ply)
    if ply then
        local pack = {}
        local act = {}
        act.state = act_state
        act.tm_over = tm_over
        pack[ACT_NAME.CROSS_NPC] = act

        act = {}
        act.state = cross_refugee.act_state
        pack[ACT_NAME.REFUGEE] = act

        Rpc:cross_act_st_ack(ply, pack)
    end
end
