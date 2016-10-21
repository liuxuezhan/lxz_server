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
    if self:do_item_check(prop_tab) == false then
    	return
    end
    if self:dec_item(idx, num, VALUE_CHANGE_REASON.USE_ITEM) == true then
    	use_item_logic[prop_tab.Action](self, prop_tab.ID, num, prop_tab)
    end
end

--使用物品检查
use_item_check = {}

use_item_check.count = function(player, count, prop_item)
    return player:get_item_num( prop_item.ID ) >= count
end

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

use_item_check.band_buff = function(player, buff_id)
    for k, v in pairs( player.bufs or {} ) do
        if v[1] == buff_id then
            if v[3] == 0 or v[3] > gTime then
                return false
            end
        end
    end
	return true
end

use_item_check.vip = function(player, lv)
	if player.vip_lv > lv then
		return false
	end
	return true
end

use_item_check.buy_res = function(player, count)
    local market = player:get_resource_market()
    if not market then return false end

    local extra = market.extra
    if not extra then 
        player:refresh_res_market() 
        extra = market.extra
    end

    if extra[ 2 ] < count then return true end
	return true
end


use_item_check.is_peace = function(player)
    for _, tid in pairs( player.busy_troop_ids or {} ) do
        local troop = troop_mng.get_troop( tid )
        if troop and troop:is_pvp() then return false end
    end
    return true
end

function do_item_check(self, prop_item)
	local con = prop_item.Check
	for k, v in pairs(con or {}) do
		if not use_item_check[v[1]](self, v[2], prop_item) then
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
    local dura = buff[2] * num
	player:add_buf(buff_id, dura)
end

--获得globe_buff加成
use_item_logic.AddBufKw = function(player, id, num, prop_item)
    local buff = prop_item.Param
    local buff_id = buff[1]
    local dura = buff[2] * num
	kw_mall.add_buf(buff_id, dura)
end

--获得军团_buff加成
use_item_logic.AddUnionBuf = function(player, id, num, prop_item)
    local buff = prop_item.Param
    local buff_id = buff[1]
    local dura = buff[2] * num
    local union = unionmng.get_union(player.uid)
    if union then
        union:add_buf(buff_id, dura)
    end
end


use_item_logic.VipEnable = function(player, id, num, prop_item)
    local dura = prop_item.Param
    player:vip_enable( dura * num )
end

use_item_logic.BuyRes = function(player, id, num, prop_item)
    local market = player:get_resource_market()
    local extra = market.extra
    local count = extra[2] + prop_item.Param * num
    if count > 999 then count = 999 end
    extra[2] = count
    market.extra = extra
end


--Param = { id, num_put, num_get }
--Check = { {"count", num_put } }

use_item_logic.Compound = function(player, id, num, prop_item)
    local id, num_put, num_get = table.unpack( prop_item.Param )
    if id and num_put and num_get then
        local target = resmng.get_conf( "prop_item", id )
        if target then
            player:add_bonus("mutex_award", {{"item", id, num_get, 10000}}, VALUE_CHANGE_REASON.COMPOUND, 1)
            if num_put > 1 then
                player:dec_item_by_item_id( prop_item.ID, num_put - 1, VALUE_CHANGE_REASON.USE_ITEM )
            end
        end
    end
end

