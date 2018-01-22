module("player_t", package.seeall)

--使用背包物品
function use_item(self, idx, num)
    local item = self:get_item(idx)
    if not item then return end
    if num <= 0 then
        WARN( "[ITEM], NUM_ERROR, use, num < 0, pid=%d, idx=%d, num=%d", self.pid, idx, num )
        return
    end

    local prop_tab = resmng.get_conf("prop_item", item[2])
    if prop_tab == nil then
        ack( self, "use_item", resmng.E_NO_CONF )
        return
    end

    if self:do_item_check(prop_tab) == false then 
        ack( self, "use_item", resmng.E_CONDITION_FAIL )
        return 
    end
    INFO( "[ITEM], use, pid=%d, itemid=%d, count=%d", self.pid, prop_tab.ID, num )

    if prop_tab.RouteToRpc then
        player_t[ prop_tab.RouteToRpc ]( self, prop_tab )
    else
        if use_item_logic[prop_tab.Action] == nil then 
            ack( self, "use_item", resmng.E_CONDITION_FAIL )
            return 
        end
        if not self:dec_item(idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
            ack( self, "use_item", resmng.E_CONSUME_FAIL )
            return 
        end
        for k, v in pairs(prop_tab.Check or {}) do
            if v[1] == "gold" then
                self:dec_gold( v[2], VALUE_CHANGE_REASON.REASON_LV_ITEM_GOLD )
            end
        end
        use_item_logic[prop_tab.Action](self, prop_tab.ID, num, prop_tab)
    end
    reply_ok(self, "use_item" )
end


function use_items( self, infos )
    for _, v in pairs( infos ) do
        local idx = v[1]
        local num = v[2]
        self:use_item( idx, num )
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

use_item_check.gold = function(p, num)
	if p.gold < num then return false end
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
        if troop and troop:is_pvp() then 
            Rpc:tips( player, 1, resmng.LG_ITEM_USE_TIP4, {} )
            return false 
        end
    end

    if is_in_black_land( player.x, player.y ) then 
        Rpc:tips( player, 1, resmng.LG_ITEM_USE_TIP4, {} )
        return false 
    end
    return true
end


use_item_check.is_not_in_black = function(player)
    local x, y = player.x, player.y
    if is_in_black_land( x, y ) then return false end
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


function get_multi_bonus( policy, tab, num )
    if num > 1 then
        local turn = 1000
        local totals = {}
        local step = math.floor(num / turn)
        local remain = num - step * turn
        if num < turn then turn = num end
        for i = 1, turn, 1 do
            local get_tab = player_t.bonus_func[policy](nil, tab)
            for k, v in pairs(get_tab) do
                if not totals[ v[1] ] then totals[ v[1] ] = {} end
                if not totals[ v[1] ][ v[2] ] then totals[ v[1] ][ v[2] ] = 0 end
                if i <= remain then
                    totals[ v[1] ][ v[2] ] = totals[ v[1] ][ v[2] ] + v[3] * ( step + 1 )
                else
                    totals[ v[1] ][ v[2] ] = totals[ v[1] ][ v[2] ] + v[3] * step
                end
            end
        end

        local its = {}
        for class, v in pairs(totals) do
            for id, num in pairs(v) do
                table.insert(its, {class, id, num})
            end
        end
        return its

    elseif num == 1 then
        return player_t.bonus_func[policy](nil, tab)
    end
end


--使用物品逻辑
use_item_logic = {}

--使用物品得到奖励
use_item_logic.AddBonus = function(player, id, num, prop_item)
    local turn = 1000
    local a = c_msec()
    for _, info in pairs(prop_item.Param or {}) do
        local policy = info[1]
        local tab = info[2]
        if num > 1 then

            local msg_notify = player_t.gPendingBonus[ player.pid ]
            if not msg_notify then
                msg_notify = {}
                player_t.gPendingBonus[ player.pid ] = msg_notify
            end

            local totals = {}
            local step = math.floor(num / turn)
            local remain = num - step * turn
            if num < turn then turn = num end
            for i = 1, turn, 1 do
                local get_tab = player_t.bonus_func[policy](player, tab)
                for k, v in pairs(get_tab) do
                    if not totals[ v[1] ] then totals[ v[1] ] = {} end
                    if not totals[ v[1] ][ v[2] ] then totals[ v[1] ][ v[2] ] = 0 end
                    if i <= remain then
                        totals[ v[1] ][ v[2] ] = totals[ v[1] ][ v[2] ] + v[3] * ( step + 1 )
                    else
                        totals[ v[1] ][ v[2] ] = totals[ v[1] ][ v[2] ] + v[3] * step
                    end
                end
            end

            for class, v in pairs(totals) do
                for id, num in pairs(v) do
                    player:do_add_bonus(class, id, num, 1, VALUE_CHANGE_REASON.USE_ITEM, false)
                    table.insert(msg_notify, {class, id, num})
                end
            end
            --Rpc:notify_bonus(player, msg_notify)

        elseif num == 1 then
            player:add_bonus(policy, tab, VALUE_CHANGE_REASON.USE_ITEM)
        end
    end
end

--充值军团礼物
use_item_logic.UnionItemPos = function(player, id, num, prop_item)
    for _, propid in pairs(prop_item.Param or {}) do
        local u = unionmng.get_union(player.uid)
        if u then
            for _,v  in pairs(u:get_members() or {}) do
                for i = 1, num do 
                    union_item.add(v,propid,UNION_ITEM.POS)
                end
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

--英雄装备
use_item_logic.HeroEquip = function(player, id, num, prop_item)
    local equip_id = prop_item.Param[1]
    local use_num = prop_item.Param[2] 
    local send_num = prop_item.Param[3]  
    if num < use_num then
        return false
    end

    for i=1, send_num, 1 do
        player:hero_equip_add(equip_id, VALUE_CHANGE_REASON.USE_ITEM)
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
            --if num_put > 1 then
            --    player:dec_item_by_item_id( prop_item.ID, num_put - 1, VALUE_CHANGE_REASON.USE_ITEM )
            --end

            local diff = num_put - num
            if diff > 0 then
                player:dec_item_by_item_id( prop_item.ID, diff, VALUE_CHANGE_REASON.USE_ITEM )

            elseif diff < 0 then
                diff = -diff
                player:inc_item( prop_item.ID, diff, VALUE_CHANGE_REASON.USE_ITEM )

            end

            player:add_bonus("mutex_award", {{"item", id, num_get, 10000}}, VALUE_CHANGE_REASON.COMPOUND, 1)
        end
    end
end


use_item_logic.RandomMove = function(player, id, num, prop_item)
    player:migrate_random()
end

use_item_logic.QuickRecover = function(player, id, num, prop_item)
    player:migrate_random()
end

