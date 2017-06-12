player_t.gClientExtra = [[
local json = require "cjson"
local app = UnityEngine.Application
local run = UnityEngine.RuntimePlatform

local pay_split = "_split_"

local function login_result( code,userid,token )
    print(code,userid,token,"login_result!!!!!!!!!")
    if code == 0 then 
        StateManager:set_current_state(StateManager.load_uiroot)
    else
        platform_type = 1 --鱼香肉丝茄子帐号
        login_type = 1
        -- loading()
        StateManager:set_current_state(StateManager.load_uiroot)
    end

end

local function logout_result( result )
    print(result)
end


function third_login( ... )
    ThirdPluginEnter.Init()
    ThirdPluginEnter.Login(login_result)
end


function init_jpush(  )
    local data = {}
    data.jpush_id = GlobalFunction.GetJpushRegistrationId()
    print("up jpush id ", data.jpush_id)
    Rpc:up_jpush_info_req(data)

    Rpc:get_server_tag_req()
end

local orders_generate_success = false
local pay_success = false
local trans_id = nil
local receipt = nil
local signature = nil
local pay_token = nil
local is_pay = false 
local consume_product_id = nil
local net_error_count = 0

local function orders_verify_callback(data)
    print(data)
    local response = json.decode(data)
    if response and response.data and response.data.trans_id then
        print("订单验证成功")
        print_table(response)
        local orders = game_db.sync_query(GAME_DB_TYPE.PLAYER_DB, sqlite3_table["pay_order"].select_single, response.data.trans_id)
        if orders and orders[1] then
            local order = orders[1]
            print_table(order)
            if order.consume_product_id then
                game_db.sync_exec(GAME_DB_TYPE.PLAYER_DB, sqlite3_table["pay_order"].delete_single,response.data.trans_id)
                ThirdPluginEnter.ConsumePay(order.consume_product_id)
                print("ConsumePay  order.consume_product_id-->", order.consume_product_id)
            end
        end
    end
    trans_id = nil
    receipt = nil
    signature = nil
    is_pay = false
end

local function orders_verify_failed(  )
    print("orders_verify_failed")
    local accounts = game_db.sync_query(GAME_DB_TYPE.SYSTEM_DB, sqlite3_table["account"].select)
    local account = accounts[1]
    local extra = account.extra
    local pay_token = json.decode(extra).pay_token
    utils.orders_verify(pay_token, trans_id, receipt, signature, orders_verify_callback, orders_verify_failed)
end

function refersh_order() --刷新订单0
    local orders = game_db.sync_query(GAME_DB_TYPE.PLAYER_DB, sqlite3_table["pay_order"].select_all)
    if orders then
        for i,v in ipairs(orders) do
            utils.orders_verify(v.pay_token, v.trans_id, v.receipt, v.signature, orders_verify_callback, orders_verify_failed)
        end
    end
end

local function orders_verify(  )
    print("orders_verify")
    local accounts = game_db.sync_query(GAME_DB_TYPE.SYSTEM_DB, sqlite3_table["account"].select)
    local account = accounts[1]
    local extra = account.extra
    pay_token = json.decode(extra).pay_token
    utils.orders_verify(pay_token, trans_id, receipt, signature, orders_verify_callback, orders_verify_failed)
    orders_generate_success = false
    pay_success = false
end



--name:商品名字
--price:商品价格 分
--extend:商品扩展信息 "server_id=3|product_id=6|open_id=qweqweqw|player_id=3001"
--desc:商品描述
function third_login_pay(name, price, extend, id, product_id, server_id, pay_result)
    -- utils.get_product_list(CHANNEL.CHANNEL_GOOGLE_PLAY, get_product_callback )
    if is_pay then
        print("正在支付中。。。。")
        GlobalFunction.show_common_warn_tips(get_value(resmng.BUYING_TIPS))
        return
    end
    local orders = game_db.sync_query(GAME_DB_TYPE.PLAYER_DB, sqlite3_table["pay_order"].select_all)
    if orders and #orders > 0 then
        refersh_order() -- 刷新订单
        GlobalFunction.show_common_warn_tips(get_value(resmng.BUYING_TIPS))
        return
    end

    local is_sanbox = not Hugula.Utils.CUtils.isRelease
    is_pay = true
    local data = {}
    data.name = name
    data.price = price
    data.extend = extend
    data.id = id
    data.product_id = product_id
    local order_expend = json.encode(data)
    local accounts = game_db.sync_query(GAME_DB_TYPE.SYSTEM_DB, sqlite3_table["account"].select)
    local account = accounts[1]
    local extra = account.extra
    local pay_token = json.decode(extra).pay_token

    local channel = CHANNEL.CHANNEL_APP_STORE
    if app.platform == run.Android then
        channel = CHANNEL.CHANNEL_GOOGLE_PLAY
    elseif app.platform == run.IPhonePlayer then
        channel = CHANNEL.CHANNEL_APP_STORE
    end

    local function pay_result_call( func_name, result )--支付回调
        print(result)
        local response = json.decode(result)
        --pay_result(func_name)
        if func_name == "purchaseSucceededEvent" then
            signature = response.signature
            receipt = response.receipt
            consume_product_id = response.consume_product_id
            print( "signature " .. signature )
            print( "receipt" .. receipt )
            if signature and receipt then
                game_db.sync_exec(GAME_DB_TYPE.PLAYER_DB, sqlite3_table["pay_order"].insert,   --存储订单
                    trans_id, signature, receipt, pay_token, consume_product_id)
                
                TalkingDataProxy.onChargeSuccess (trans_id)
                AdjustProxy.Recharge(price, "usd")
                print("购买成功，校验订单")
                orders_verify(signature)    
            else
                print("支付失败")
                is_pay = false
            end
        elseif func_name == "queryInventoryFailedEvent" then
            print("查询失败 " ..  response.error)
            is_pay = false
        elseif func_name == "purchaseFailedEvent" then
            is_pay = false
            print("支付失败 " ..  response.error)
            -- ThirdPluginEnter.QueryPurchase()
        else
            is_pay = false
        end
    end

    local function orders_generate_callback(data) --创建订单成功回调
        local response = json.decode(data)
        print("orders_generate_callback")
        print_table(response)
        if tonumber(response.code) == 0 then
            net_error_count = 0
            trans_id = response.data.trans_id
            print("ThirdPluginEnter.Pay")
            TalkingDataProxy.onChargeRequest(trans_id, name, price, "usd", price, channel)
            local  tab_extend = json.decode(extend)
            tab_extend.trans_id = trans_id
            local new_extend = json.encode(tab_extend)
            ThirdPluginEnter.Pay(name, price, new_extend, id, product_id, pay_result_call)
        else
            print_table(response)
            print("创建订单失败")
        end
    end

    local function orders_generate_failed(  )--创建订单失败回调
        print("orders_generate_failed")
        if net_error_count > 3 then
            net_error_count = 0
            GlobalFunction.show_common_tips(get_value(resmng.CONNECT_FAIL))
            return
        end
        net_error_count = net_error_count + 1
        is_pay = false
        utils.orders_generate(channel, pay_token, id, product_id, 1, order_expend, server_id, is_sanbox, orders_generate_callback, orders_generate_failed)
    end

    utils.orders_generate(channel, pay_token, id, product_id, 1, order_expend, server_id, is_sanbox, orders_generate_callback, orders_generate_failed)
    --充值请求
end
]]

