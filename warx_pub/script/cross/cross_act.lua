module( "cross_act", package.seeall ) 

act_state = act_state or 0

refugee_state = refugee_state  or 0

group_info = group_info or {}

tm_over = tm_over or 0

function rec_cross_act_st(act_st)
    local last_st = act_state
    for k, st in pairs(act_st or {}) do
        if k == ACT_NAME.CROSS_NPC then
            act_state = st.state or 0
            tm_over = st.tm_over or 0
        elseif k == ACT_NAME.REFUGEE then
            refugee.act_state = st.state or 0
            refugee_state = st.state or 0
        end
    end

    if last_st == CROSS_STATE.FIGHT and act_state == CROSS_STATE.PEACE then
        drop_back_all_ply()
    end
end

function load_data()
--    Rpc:callAgent(gCenterID, "cross_act_st_req", 1)
end

function cross_act_st_req(ply)
    if ply then
        local pack = {}
        local act = {}
        act.state = act_state
        act.tm_over = tm_over
        pack[ACT_NAME.CROSS_NPC] = act

        act = {}
        act.state = refugee.act_state
        pack[ACT_NAME.REFUGEE] = act

        pack.group_info = group_info {}

        Rpc:cross_act_st_ack(ply, pack)
    end
end

function drop_back_all_ply()
    for _, ply in pairs(gPlys or {}) do
        if check_ply_cross(ply) then
            ply:cross_migrate_back(self.emap, self.x, self.y)
        end
    end
end
