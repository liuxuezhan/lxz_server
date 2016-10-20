--------------------------------------------------------------------------------
-- Desc     : check config.
-- Author   : Yang Cong
-- History  :
--     2016-1-11 15:34:12 Created
-- Copyright: Chengdu Tapenjoy Tech Co.,Ltd
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
module("resmng", package.seeall)


--------------------------------------------------------------------------------
-- Function : check config.
-- Argument : file_name
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function do_check(file_name)
    if resmng["check_" .. file_name] then
        LOG("check config[%s]: begin.", file_name)
        resmng["check_" .. file_name]()
    else
        LOG("check config[%s]: not found check function, ignore.", file_name)
    end
end


--------------------------------------------------------------------------------
-- Function : check functions
-- Argument : NULL
-- Return   : NULL
-- Others   : function name = "check_" .. file_name
--------------------------------------------------------------------------------
function check_prop_hero_basic()
    -- TODO: 稍后添加
end


function check_prop_hero_lv_exp()
    -- TODO: 稍后添加
end


function check_prop_hero_quality()
    -- TODO: 稍后添加
end


function check_prop_hero_skill_exp()
    -- TODO: 稍后添加
end


function check_prop_hero_star_up()
    -- TODO: 稍后添加
end

