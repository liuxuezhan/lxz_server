player_t.gClientExtra = [[
local declare_info = LuaItemManager:get_item_obejct("declare_info")

declare_info.data_show = nil
declare_info.cfg_city = nil
declare_info.tab_cond = nil
declare_info.root_rf = nil

local desc_id = 
{
    resmng.TIPS_TW_LINE,
    resmng.TIPS_TW_TIME,
    resmng.TIPS_TW_CASTLE_LV,
    resmng.TIPS_TW_UNION_LV,
    resmng.TIPS_TW_CITYLIMIT,
    resmng.TIPS_TW_DECLARETIME,
    resmng.TIPS_TW_UNIONPOINT,
    resmng.TIPS_TW_NUMBER,
    resmng.TIPS_TW_CITYNUM,
}

function declare_info.on_conditem_render(sritem,index,data)
    sritem.gameObject:SetActive(true)
    local str = get_value(desc_id[data.id])
    if data.arg then str = string.format(str,data.arg) end
    sritem:Get(1).text = str
    sritem:Get(2).text = data.val or ""
    if not data.hide then
        sritem:Get(3):SetActive(data.reach)
        sritem:Get(4):SetActive(not data.reach)
    else
        sritem:Get(3):SetActive(false)
        sritem:Get(4):SetActive(false)
    end
    sritem:Get(5).enabled = index % 2 == 0
end

function declare_info.update_page()
    if not declare_info.data_show or not declare_info.tab_cond or not declare_info.cfg_city then return end
    local tab_cond = declare_info.tab_cond
    local cfg_city = declare_info.cfg_city
    local root_rf = declare_info.root_rf
    local scr_data = {}
    if true ~= tab_cond.is_connect then
        local tab = {id = 1,reach = false}
        table.insert(scr_data,tab)
    end

    if 2 < tab_cond.union_join and (timekit.get_server_time() - tab_cond.union_tm_join) < 12 * 60 * 60 then
        local tab = {id = 2,reach = false}      
        table.insert(scr_data,tab)
    end

    local zone_lv = utils.get_reszone_level(cfg_city.X,cfg_city.Y)
    if not can_enter(utils.get_castle_lv(),zone_lv) then
        local tab = {id = 3,reach = false,arg = enter_lvreszone_need(zone_lv)}
        table.insert(scr_data,tab)
    end

    local self_uinfo = Model.unionmember_bypid(Model.get_pro("pid"))
    if self_uinfo.rank < 4 then
        local tab = {id = 4,reach = false}
        table.insert(scr_data,tab)
    end

    local myunion = Model.get_selfunion() or {}
    local oc_limit = get_can_occupycity_count(table.get_elem_size(Model.get_selfunion().member or {}))
    local tab5 = {id = 5,reach = oc_limit > tab_cond.occu_num,val = tab_cond.occu_num .. "/" .. oc_limit}
    table.insert(scr_data,tab5)

    local tab6 = {id = 6,reach = tab_cond.declare_time < 3,val = (3 - tab_cond.declare_time) .. "/3"}
    table.insert(scr_data,tab6)

    local cfg_consume = resmng.get_conf("prop_tw_consume",cfg_city.Lv)
    local tab7 = {id = 7,reach = nil ~= cfg_consume and cfg_consume.Consume <= tab_cond.donate}
    tab7.val = tab_cond.donate .. "/" .. cfg_consume.Consume
    table.insert(scr_data,tab7)

    local tab8 = {id = 8,reach = cfg_consume.Condition[2] <= tab_cond.lv_num}
    tab8.arg = cfg_consume.Condition[1]
    tab8.val = tab_cond.lv_num .. "/" .. cfg_consume.Condition[2]
    table.insert(scr_data,tab8) 

    local tab9 = {id = 9,hide = true,reach = true}
    table.insert(scr_data,tab9)

    root_rf:Get(1).data = scr_data
    root_rf:Get(1):Refresh(-1,-1)

    for k,v in ipairs(scr_data) do
        if not v.reach then
            root_rf:Get(2).interactable = false
            return      
        end
    end
    root_rf:Get(2).interactable = true
end


function declare_info.on_get_declareinfo( tab )
    local eid,data = unpack(tab)
    if eid ~= declare_info.data_show.eid then return end
    
    declare_info.tab_cond = data
    declare_info.update_page()
end

function declare_info:show_info(_data)
    if not _data then utils.printerror("nil data to show declare_info,failed!") return end
    declare_info.data_show = _data
    declare_info.cfg_city = resmng.get_conf("prop_world_unit",declare_info.data_show.propid)
    self:add_to_state()
end

function declare_info:on_assets_load(items)
    declare_info.root_rf = LuaHelper.GetComponent(self.assets[1].root,CSNameSpace.ReferGameObjects) 
    declare_info.root_rf:Get(1).onItemRender = declare_info.on_conditem_render
end

function declare_info:on_showed( ... )
    Proxy:binding(MSG_TYPE.DECLARE_INFO_GOT,declare_info.on_get_declareinfo)    
    Rpc:declare_tw_status_req(declare_info.data_show.eid)
end

function declare_info:on_hide( ... )
    Proxy:unbinding(MSG_TYPE.DECLARE_INFO_GOT,declare_info.on_get_declareinfo)
    declare_info.data_show = nil
end

function declare_info:on_click(obj,arg)
    local _cmd =obj.name
    if "close_btn" == _cmd then
        self:remove_from_state()
    elseif "confirm_declare" == _cmd then
        Rpc:declare_tw_req(declare_info.data_show.eid)
        self:remove_from_state()
    end
end
]]

