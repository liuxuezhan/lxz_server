--config.Chat_addr = "49.51.42.232"
player_t.gClientExtra = [[
Net.is_connected = true
Net.onConnect = function()
	Net.is_connected = true

	print("Lua Net.onConnect") 
	Analytics:svr_connected()
	if Net.enter_main then
    	print("enter_main is true")
    	local open_id = SDK:get_open_id()
    	local zone_id = SDK:get_zoneid()
    	local pid     = SDK:get_pid()
    	print(string.format("open_id=%s, zone_id=%s, pid=%s", open_id,zone_id,pid))
    	login_net.send_join_game( zone_id, open_id, pid, 0)
	end
	Proxy:distribute(MSG_TYPE.NET_CONNECT_SUCCESS)     
end

Net.onDisconnect = function()
	if not Net.is_connected then return end
	Net.is_connected=false
	print("Lua Net.onDisconnect")
	Proxy:distribute(MSG_TYPE.NET_DISCONNECT)
end

Net.onReconnect = function()
	Net.is_connected = true
	print("onReconnect")
end

Net.onConnectError = function()
	if not Net.is_connected then return end
	Net.is_connected=false
	print("onConnectError")
	Proxy:distribute(MSG_TYPE.NET_CONNECT_ERROR)
end

Net.NetEvent = {
	UNKOWN = 0,
	CONNECT = 1,
	DISCONNECT = 2,
	RECONNECT = 3,
	CONNECT_ERROR = 4,
	RECEIVE_ERROR = 5,
	SEND_ERROR = 6,
}

Net.netEventHandler = {
	[Net.NetEvent.UNKOWN] = Net.onUnkownError,
	[Net.NetEvent.CONNECT] = Net.onConnect,
	[Net.NetEvent.DISCONNECT] = Net.onDisconnect,
	[Net.NetEvent.RECONNECT] = Net.onReconnect,
	[Net.NetEvent.CONNECT_ERROR] = Net.onConnectError,
	[Net.NetEvent.RECEIVE_ERROR] = Net.onDisconnect,
	[Net.NetEvent.SEND_ERROR] = Net.onDisconnect,
}

Net.netHandler = function(packet)
	local ptype = packet:Type()
	if ptype < 100 then
		local func = Net.netEventHandler[ptype]
		if func then
			func()
			return true
		end
	end

	local dealed, pname = Rpc:parseRpc(packet)
	if dealed then
	end
	return dealed
end

WarNet.main.luaNetHandler = Net.netHandler


local _resmng = resmng
local data = _resmng.prop_guideData
data[_resmng.GUIDE_STEP_13][20] = nil
data[_resmng.GUIDE_STEP_14][20] = nil
data[_resmng.GUIDE_STEP_15][20] = nil
data[_resmng.GUIDE_STEP_16][20] = nil
data[_resmng.GUIDE_STEP_30][20] = nil
data[_resmng.GUIDE_STEP_50][20] = 170
data[_resmng.GUIDE_STEP_87][20] = 90
data[_resmng.GUIDE_STEP_91][20] = 100
data[_resmng.GUIDE_STEP_93][20] = nil
data[_resmng.GUIDE_STEP_94][20] = nil
data[_resmng.GUIDE_STEP_103][20] = 30
data[_resmng.GUIDE_STEP_104][20] = 40
data[_resmng.GUIDE_STEP_111][20] = 10
data[_resmng.GUIDE_STEP_112][20] = 20
data[_resmng.GUIDE_STEP_120][20] = 110
data[_resmng.GUIDE_STEP_122][20] = 160
data[_resmng.GUIDE_STEP_126][20] = 120
data[_resmng.GUIDE_STEP_130][20] = 130
data[_resmng.GUIDE_STEP_131][20] = 140
data[_resmng.GUIDE_STEP_133][20] = 150




function utils.on_pay(buy_id, pay_result)
	local buy_config = resmng.prop_buyById(buy_id)
	if  SDK:is_sqsdk() then
        local id = buy_config.ID
		local data = {}
		data.appid = AppID
		data.pid = id
		local sign = utils.create_http_sign(data)
		data.sig = sign
		local param = json.encode(data)
		local server_id = SDK:get_zoneid()
		local pid = SDK:get_pid()
		local outOrderID = server_id.."_"..pid.."_"..timekit.get_server_time()
		local gold = buy_config.Gold
		if buy_config.ExtraGold then
            gold = gold+buy_config.ExtraGold
        end
        Analytics:wishlist(id)

        local function pay_callback(ret)
		-- body
			Analytics:purchase_success(id)
			if type(ret.data) == "string" then
				local msg = ret.data
				ret.data = {}
				ret.data.msg = string.format("%s(%s)", msg, ret.code)
			elseif type(data.data) == "table" then
				ret.data.msg = string.format("%s(%s)", ret.data.msg or "", ret.code) 
			end

			if pay_result then
				pay_result(ret)
			else
				if tonumber(ret.code) ~= 1 then
					local tip = get_value(resmng.PAY_FAIL)
					if ret.data.msg then
						tip = string.format("%s[%s]", tip, ret.data.msg)
					end
					GlobalFunction.show_alert_notice(tip)
				end 
			end
		end
		SDK:pay(buy_config.AppleBuyID,
			buy_config.NewPrice_US,
			server_id,
			pid,
			Model.get_pro("name"),
			Model.get_pro("lv") or 1,
			gold,
			outOrderID,
			param,
			pay_callback)
		return 
	end
end

local clientlan = UnityEngine.PlayerPrefs.GetInt(PLAYER_PREFS_KEY.LANGUAGE,UnityEngine.Application.systemLanguage)
if 6 == clientlan then clientlan = 40 end
if clientlan ~= 40 then
	resmng.propLang[resmng.YUEKA_LABLE_NAME_101] = "Speedup"
	resmng.propLang[resmng.YUEKA_LABLE_NAME_102] = "Resource"
	resmng.propLang[resmng.YUEKA_LABLE_NAME_103] = "Hero"
	resmng.propLang[resmng.YUEKA_LABLE_NAME_104] = "Buff"
end

local first_buy = LuaItemManager:get_item_object("first_buy")

function first_buy.pay_cb( result )
	local self = first_buy
	self.lock_buy = false
	
	if SDK:is_sqsdk() then 
		if tonumber(result.code) == 1 then
			self:remove_from_state()	
			popupmgr.queue_show()
		else 
			local tip = get_value(resmng.PAY_FAIL)
			if result.data.msg then
				tip = tip..result.data.msg
			end
			GlobalFunction.show_alert_notice(tip)
		end
	else
		if result == "purchaseSucceededEvent" then	
			self:remove_from_state()
			popupmgr.queue_show()
		end
	end
end

function first_buy:on_click(obj,arg)
	local _cmd =obj.name
	if "close_btn" == _cmd then
		self:remove_from_state()
	elseif "buy_btn" == _cmd then
		if self.lock_buy then
			GlobalFunction.show_alert_notice(get_value(resmng.BUYING_TIPS))
			return
		end
		self.lock_buy = true

		utils.on_pay(self.data.ID, self.pay_cb)
	elseif "icon_skill" == _cmd then
		local config = resmng.prop_hero_basicById(14)
		if config then
			local prop_skill = resmng.prop_skillById(config.TalentSkill)
			GlobalFunction.show_click_tips(prop_skill.Detail)
		end
    end
end

]]

INFO( "doExtra---------" )
