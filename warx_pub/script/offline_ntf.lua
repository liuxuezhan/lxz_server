module("offline_ntf", package.seeall)


function post(action, target, ...)
    --if ply:is_online() then
    --    return
    --end
    --
    LOG("post %s", action)
    if not config.OfflineNtf or config.OfflineNtf == 0 then
        return
    end

    if not ntf_action[action] then
        return
    end

    if target and target ~= "all" then

        if is_ply(target) and ((not target.jpush_id) or target.jpush_id == "" ) then
            return
        end

        local prop = resmng.prop_offline_notify[action]
        if is_ply(target) then
            LOG("post %s %s", action, target.jpush_id)

            local sub_ntf_list = target.sub_ntf_list or {}
            if not sub_ntf_list[action] then
                if not prop then
                    return
                elseif prop.Default == 1 then
                    sub_ntf_list[action] = 1
                    target.sub_ntf_list = sub_ntf_list
                    Rpc:push_ntf_list_ack(target, sub_ntf_list)
                else
                    sub_ntf_list[action] = 0
                    target.sub_ntf_list = sub_ntf_list
                    return
                end
            else
                if sub_ntf_list[action] == 0 then
                    return 
                end
            end
        end

        local offline_ntf_status = target.offline_ntf_status or {}
        if offline_ntf_status[action] then
            if prop.Time and ( offline_ntf_status[action] - gTime ) < prop.Time then
                return
            end
        end

        offline_ntf_status[action] = gTime
        target.offline_ntf_status = offline_ntf_status
    end

    ntf_action[action](action, target, ...)
end

function get_language_tag(language)
    local prop = resmng.prop_language_cfg[language]
    if not prop then
        return "en"
    end

    return prop.LanOffline
end

function replace_param(lang, lang_id, param)
    local prop = resmng.prop_language_offline[lang_id]
    if not prop then
        return
    end

    local msg = prop[get_language_tag(lang)]
    if not msg then
        return
    end

   -- if param then
   --     print("offline ntf", param[1])
   --     return param[1]
   -- else
   --     return msg

   -- end

   local msg1 = string.format_ts(msg, param)
   --print("offline ntf", msg1)
   return msg1

    --for k, v in pairs(param or {}) do
    --    local idx = "%".. tostring(k) .. "$s"
    --    if type(v) == "table" then
    --        msg = string.gsub(msg, idx, word)
    --    else
    --        msg = string.format_ts(msg, {v})
    --    end
    --end

end


ntf_action = {}

ntf_action[resmng.OFFLINE_NOTIFY_ATTACK] = function(action, ply, atk_ply, union)
    union = union or {}
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local word = atk_ply.name
    if union.alias then
        word = "(" .. union.alias .. ")" .. word
    end
    local param = {word}

    local msg = replace_param(ply.language, prop.Inform, param)

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_SCOUT] = function(action, ply, atk_ply, union)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    union = union or {}
    local word = atk_ply.name
    if union.alias then
        word = "(" .. union.alias .. ")" .. word
    end
    local param = {word}

    local msg = replace_param(ply.language, prop.Inform, param)

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_MASS] = function(action, ply, atk_ply, union)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    union = union or {}
    local word = atk_ply.name
    if union.alias then
        word = "(" .. union.alias .. ")" .. word
    end
    local param = {word}

    local msg = replace_param(ply.language, prop.Inform, param)

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_GATHER] = function(action, ply)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform)

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_RECRUIT] = function(action, ply)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform)

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_PROTECT] = function(action, ply)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform)

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_MAIL] = function(action, ply, from_ply, union, word)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    union = union or {}
    local word = from_ply.name
    if union.alias then
        word = "(" .. union.alias .. ")" .. word
    end
    local param = {word}

    local msg = replace_param(ply.language, prop.Inform, param)

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_RESEARCH] = function(action, ply, tech_id)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local tech_prop = resmng.prop_tech[tech_id]
    if not tech_prop then
        return
    end

    local lang = resmng.prop_language_offline[tech_prop.NameOffline]
    if not lang then
        return
    end

    local param = lang[get_language_tag(ply.language)] .. " lv" ..tostring(tech_prop.Lv)

    local msg = replace_param(ply.language, prop.Inform, {param})

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_BUILD] = function(action, ply, build_id)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local build_prop = resmng.prop_build[build_id]
    if not build_prop then
        return
    end

    local lang = resmng.prop_language_offline[build_prop.NameOffline]
    if not lang then
        return
    end

    local param = lang[get_language_tag(ply.language)] .. " lv" ..tostring(build_prop.Lv)

    local msg = replace_param(ply.language, prop.Inform, {param})

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_DECLARE] = function(action, ply, npc_name)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local lang = resmng.prop_language_offline[npc_name]
    if not lang then
        return
    end

    local param = lang[get_language_tag(ply.language)] 

    local msg = replace_param(ply.language, prop.Inform, {param})

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_BE_DECLARE] = function(action, ply, npc_name, unions)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local lang = resmng.prop_language_offline[npc_name]
    if not lang then
        return
    end

    local param = lang[get_language_tag(ply.language)]

    local msg = replace_param(ply.language, prop.Inform, {param, unions[1]})

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_FIGHT] = function(action, ply, npc_name)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local lang = resmng.prop_language_offline[npc_name]
    if not lang then
        return
    end

    local param = lang[get_language_tag(ply.language)]

    local msg = replace_param(ply.language, prop.Inform, {param})

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_BE_FIGHT] = function(action, ply, npc_name)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local lang = resmng.prop_language_offline[npc_name]
    if not lang then
        return
    end

    local param = lang[get_language_tag(ply.language)]

    local msg = replace_param(ply.language, prop.Inform, {param})

    local audience = {
            ["registration_id"] = {ply.jpush_id}
    }

    push_offline_ntf(audience, msg)

end

ntf_action[resmng.OFFLINE_NOTIFY_KING] = function(action)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    --local lang = 40
    --local msg = replace_param(lang, prop.Inform, {})
    --local audience = "all"
    --push_offline_ntf(audience, msg)
    --
    --
    local audience = {}
    --audience.tag_and = {"warxmap_1001"}
    audience.tag_and = {get_server_tag()}
    ntf_by_all_language(audience, prop.Inform, {})

end

ntf_action[resmng.OFFLINE_NOTIFY_TOWER] = function(action)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

   -- local lang = 40

   -- local msg = replace_param(lang, prop.Inform, {})

   -- local audience = "all"

   -- push_offline_ntf(audience, msg)
    local audience = {}
    audience.tag_and = {get_server_tag()}
    ntf_by_all_language(audience, prop.Inform, {})

end

ntf_action[resmng.OFFLINE_NOTIFY_REBEL] = function(action, union)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    lang = union.lang

    local msg = replace_param(lang, prop.Inform, {})

    local audience = {
            ["registration_id"] = {get_union_jpush_list(union)}
    }

    push_offline_ntf(audience, msg)

end

function get_union_jpush_list(union)
    local jpush_id_list = {}
    local members = union:get_members()
    for k, v in pairs(members or {}) do
        if v.jpush_id then
            table.insert(jpush_id_list, v.jpush_id)
        end
    end
    return jpush_id_list
end

ntf_action[resmng.OFFLINE_NOTIFY_TIME_ACTIVITY] = function(action, act_idx)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local act_prop = resmng.prop_weekly_activity[act_idx]
    if not act_prop then
        return
    end

    local param_prop = resmng.prop_language_offline[act_prop.TitleOffline]
    if not param_prop then
        return
    end

   -- lang = 40

   -- local param = param_prop[get_language_tag(lang)]

   -- local msg = replace_param(lang, prop.Inform, param)

   -- local audience = "all"

   -- push_offline_ntf(audience, msg)
    local audience = {}
    audience.tag_and = {get_server_tag()}
    ntf_by_all_language(audience, prop.Inform, param)

end

function ntf_by_all_language(audience, ntf_id, param)
    for k, v in pairs(resmng.prop_language_cfg or {}) do
        local target = copyTab(audience) or {}

        local prop = resmng.prop_language_offline[ntf_id]
        if not prop then
            return
        end

        local tag = get_language_tag(k)
        local lang = k

        if not prop[tag] then
       --     tag = "zhCN"
            lang = 10
        end

        local msg = replace_param(lang, ntf_id, param)

        local tag_and = target.tag_and or {}
        table.insert(tag_and, tag)
        target.tag_and= tag_and

        push_offline_ntf(target, msg)
    end
end

function get_server_tag()
    local tag = config.Game .. config.Tips
    return tag
end







