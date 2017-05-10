gmcmd.block_account = function( open_ids, time )
    player_t.set_block( open_ids[1], tonumber(time) )
    return {code = 1, msg = "success"}
end

gmcmd.gmcmd_table.blockaccount =  { 4,              block_account,         "no login for account",                     "blockaccount=time=pid" },

