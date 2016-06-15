module("player_t")

--使用背包物品
function use_item(self, idx, num)
    local item = self:get_item(idx)
    local prop_tab = resmng.get_conf("prop_item", item[2])
    if prop_tab == nil then
        return
    end
    if use_item_logic[prop_tab.Action] == nil then
        return
    end
    if self:use_item_check(prop_tab) == false then
    	return
    end
    if self:dec_item(idx, num, VALUE_CHANGE_REASON.USE_ITEM) == true then
    	use_item_logic[prop_tab.Action](self, prop_tab.ID, num, prop_tab)
    end
end

--使用物品检查
use_item_check = {}

use_item_check.castle = function(player, lv)
	if player:get_castle_lv() < lv then
		return false
	end
	return true
end

use_item_check.level = function(player, lv)
	if player.lv > lv then
		return false
	end
	return true
end

use_item_check.mutex_buff = function(player, buff_id)
	return true
end

use_item_check.vip = function(player, lv)
	if player.vip_lv > lv then
		return false
	end
	return true
end

function use_item_check(self, prop_item)
	local con = prop_item.Check
	for k, v in pairs(con or {}) do
		if use_item_check[v[1]](self, v[2]) == false then
			return false
		end
	end
	return true
end


--使用物品逻辑
use_item_logic = {}

--使用物品得到奖励
use_item_logic.AddBonus = function(player, id, num, prop_item)
    for _, info in pairs(prop_item.Param or {}) do
        local policy = info[1]
        local tab = info[2]
        if num > 10 then
            local totals = {}
            local step = math.floor(num / 10)
            for i = 1, 10, 1 do
                local get_tab = player_t.bonus_func[policy](player, tab)
                for k, v in pairs(get_tab) do
                    if not totals[ v[1] ] then totals[ v[1] ] = {} end
                    if not totals[ v[1] ][ v[2] ] then totals[ v[1] ][ v[2] ] = 0 end
                    totals[ v[1] ][ v[2] ] = totals[ v[1] ][ v[2] ] + v[3] * step
                end
            end
            local remain = num - step * 10
            if remain > 0 then
                local get_tab = player_t.bonus_func[policy](player, tab)
                for k, v in pairs(get_tab) do
                    if not totals[ v[1] ] then totals[ v[1] ] = {} end
                    if not totals[ v[1] ][ v[2] ] then totals[ v[1] ][ v[2] ] = 0 end
                    totals[ v[1] ][ v[2] ] = totals[ v[1] ][ v[2] ] + v[3] * remain
                end
            end
            local msg_notify = {}
            for class, v in pairs(totals) do
                for id, num in pairs(v) do
                    player:do_add_bonus(class, id, num, 1, VALUE_CHANGE_REASON.USE_ITEM, false)
                    table.insert(msg_notify, {class, id, num})
                end
            end
            Rpc:notify_bonus(player, msg_notify)
        else
            for i = 1, num, 1 do
                player:add_bonus(policy, tab, VALUE_CHANGE_REASON.USE_ITEM)
            end
        end
    end
end

--英雄卷轴
use_item_logic.UseHeroCard = function(player, id, num, prop_item)
    local hero_id = prop_item.Param
    for i = 1, num, 1 do 
        player:make_hero(hero_id)
    end
end

--获得buff加成
use_item_logic.AddBuf = function(player, id, num, prop_item)
    local buff = prop_item.Param
    local buff_id = buff[1]
    local dura = buff[2]
	player:add_buf(buff_id, dura)
end


use_item_logic.VipEnable = function(player, id, num, prop_item)
    local dura = prop_item.Param
    player:vip_enable( dura * num )
end

