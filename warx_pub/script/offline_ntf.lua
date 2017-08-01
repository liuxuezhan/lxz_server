module("offline_ntf", package.seeall)


function post(action, target, ...)
    --if ply:is_online() then
    --    return
    --end
    --
    LOG("post %s", action)

    if not ntf_action[action] then
        return
    end

    if target and target ~= "all" then
        if config.OfflineNtf == 1 then
            if is_ply(target) and ((not target.jpush_id) or target.jpush_id == "" ) then
                return
            end
        elseif config.OfflineNtf == 2 then
            if is_ply(target) and ((not target.fcm_id) or target.fcm_id == "" ) then
                return
            end
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

function get_lang_str(prop, language)

    local lang_tag = get_language_tag(language)

    if prop[lang_tag] then
        return prop[lang_tag]
    end

    lang_tag = get_language_tag(10) 
    if prop[lang_tag] then
        return prop[lang_tag]
    end

    return
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
    if not msg then
        return 
    end

    if not config.OfflineNtf or config.OfflineNtf == 0 then
        return
    end

    if config.OfflineNtf == 1 then
    local audience = {
            ["registration_id"] = {ply.jpush_id},
    }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
    local audience = {
            ["fcm_id"] = ply.fcm_id
    }
        fcm(audience, msg)
    end

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
    if not msg then
        return 
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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
    if not msg then
        return 
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

end

ntf_action[resmng.OFFLINE_NOTIFY_GATHER] = function(action, ply)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform)
    if not msg then
        return 
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

end

ntf_action[resmng.OFFLINE_NOTIFY_RECRUIT] = function(action, ply)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform)
    if not msg then
        return 
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

end

ntf_action[resmng.OFFLINE_NOTIFY_PROTECT] = function(action, ply)
    local prop = resmng.prop_offline_notify[action]
    if not prop then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform)
    if not msg then
        return 
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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
    if not msg then
        return 
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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

    local lang_str = get_lang_str(lang, ply.language)
    if not lang_str then
        return 
    end

    local param = lang_str .. " lv" ..tostring(tech_prop.Lv)

    local msg = replace_param(ply.language, prop.Inform, {param})
    if not msg then
        return
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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

    local lang_str = get_lang_str(lang, ply.language)
    if not lang_str then
        return 
    end

    local param = lang_str .. " lv" ..tostring(build_prop.Lv)

    local msg = replace_param(ply.language, prop.Inform, {param})
    if not msg then
        return
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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

    local param = get_lang_str(lang, ply.language)
    if not param then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform, {param})
    if not msg then
        return
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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

    local param = get_lang_str(lang, ply.language)
    if not param then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform, {param, unions[1]})
    if not msg then
        return
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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

    local param = get_lang_str(lang, ply.language)
    if not param then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform, {param})
    if not msg then
        return
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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

    local param = get_lang_str(lang, ply.language)
    if not param then
        return 
    end

    local msg = replace_param(ply.language, prop.Inform, {param})
    if not msg then
        return
    end

    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {ply.jpush_id},
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["fcm_id"] = ply.fcm_id
        }
        fcm(audience, msg)
    end

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
    if not msg then
        return
    end


    if config.OfflineNtf == 1 then
        local audience = {
            ["registration_id"] = {get_union_push_list(union, "jpush")}
        }
        push_offline_ntf(audience, msg)
    elseif config.OfflineNtf == 2 then
        local audience = {
            ["registration_ids"] = {get_union_push_list(union, "fcm")}
        }
        fcm(audience, msg)
    end

end

function get_union_push_list(union)
    local push_id_list = {}
    local members = union:get_members()
    for k, v in pairs(members or {}) do
        if config.OfflineNtf == 1 then
            if v.jpush_id then
                table.insert(push_id_list, v.jpush_id)
            end
        elseif config.OfflineNtf == 2 then
            if v.fcm_id then
                table.insert(push_id_list, v.fcm_id)
            end
        end
    end
    return push_id_list
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

    local gen_cond_str = function(tag_and)
        local str
        for _, v in pairs(tag_and or {}) do
            if not str then
                str = "'" .. v .. "' in topics"
            else
                str = str .. " && '" .. v .. "' in topics"
            end
        end
        return str
    end

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
        if not msg then
            return
        end

        local tag_and = target.tag_and or {}
        table.insert(tag_and, tag)
        target.tag_and= tag_and


        if config.OfflineNtf == 1 then
            push_offline_ntf(target, msg)
        elseif config.OfflineNtf == 2 then
            target.condition = gen_cond_str(tag_and)
            fcm(target, msg)
        end
    end
end

function get_server_tag()
    local tag = config.Game .. config.Tips
    return tag
end

function fcm(target, msg)
    INFO("fcm %s, %s", target.registration_id, msg)
    to_tool( 0, { 
        type = "common", 
        mode = "fcm", 
        url = "https://fcm.googleapis.com/fcm/send",
        method = "post", 
        --header = "key=AAAATbs2Ld8:APA91bGsqPHCQIqujlf04Nua5wNmF_LMzoc66ZS86OYofG0i8b8Wy2wEe7LHUkvaRlyuChEzjNkxobqMh2BjWgpTlKjvHawoZGl_KPIpq67n6J4_8me6JZ6oQvjN9cENAd5qnzEsVB4j ",  
        header = "key=AAAARL0rHjA:APA91bHCLVQsAwpYLOWgiGLwJ44nHYMgDO_gq91xVBWw1-RDfqiw-EoOIpXG3aUzCsNItyb8ofTQBpkYO3DgOKjNMmck0pFwkVaz_Lx2Uurq1xoLK2DvugXTnPAykUGoREut6HNC7ImO",  
        registration_ids = target.registration_ids,
        to = target.fcm_id,
        condition = target.condition,
        --condition =  "'warxmap_7' in topics && 'zh-CN' in topics",
        notification = {
            body = msg,
        },
    } )
end

function push_offline_ntf(audience, msg)
    INFO("do jpush %s, %s", audience.registration_id, msg)
    to_tool( 0, { 
        type = "common", 
        mode = "jpush", 
        url = "https://api.jpush.cn/v3/push", 
        method = "post", 
        --header = "NDMwMDU2NzliZGMyYThjNzE2NTRmODQ0Ojk5YTFjZTYwOTY0MGQ3MGUzOTJiNTUyYg==",  
        header = "YTAzZWEyOWVhYmU2OGJlOTFjNzAwMjNmOjUwMTcwZGI1NzJkMzU3NDA0OWM3ZjQ4Mw==",  
        -- base64 of "43005679bdc2a8c71654f844:99a1ce609640d70e392b552b",
        --        platform = offline_ntf.get_server_tag(),
        platform = "all",
        audience = audience,
        notification = {
            alert = msg,
            android = {
                alert = msg,
                extras = {
                    android_key1 = "android-value1",
                }
            },
            ios = {
                alert = msg,
                sound = "sound.caf",
                ["content-available"] = true,
                badge = "+1",
            }
        },
        options = {
            time_to_live = 0,
            apns_production = config.JpuahMode or "false"
        }
    })
end







