module("resmng", package.seeall)

local BasePath = ""
--------------------------------------------------------------------------------
do_load(BasePath .. "prop_cron")

--do_load(BasePath .. "define_tw_union_consume")

--do_load(BasePath .. "prop_language_cfg")


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Function : 根据 prop_name，index 获取配置
-- Argument : prop_name, index
-- Return   : table or nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_conf(prop_name, index)
    if not prop_name or not index then
        ERROR("get_conf: prop_name = %s, index = %s", prop_name or "nil", index or -1 .. "")
        return
    end

    local conf = resmng[prop_name] and resmng[prop_name][index]
    if not conf then
        ERROR("get_conf: lost config. prop_name = %s, index = %s", prop_name or "nil", index or -1 .. "")
        return
    else
        return conf
    end
end





