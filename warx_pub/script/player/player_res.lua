module("player_t")

function refresh_res_market(self)
    local market = self:get_resource_market()
    if not market then return end

    local t = {
        200, 0,    -- count total, count free,
        {
            {1,0,0,1}, -- resource id,  count fresh, count buy, combo
            {2,0,0,1}, -- resource id,  count fresh, count buy, combo
            {3,0,0,1}, -- resource id,  count fresh, count buy, combo
            {4,0,0,1}, -- resource id,  count fresh, count buy, combo
            {8,0,0,1}, -- resource id,  count fresh, count buy, combo
        }
    }

    local info = market.extra
    if info[2] and type(info[2]) == "number" then t[2] = info[2] end -- count free
    market.extra = t
end

function buy_res(self, id)
    local market = self:get_resource_market()
    if not market then return end

    local extra = market.extra
    if not extra then return end

    local marketlv = resmng.get_conf("prop_build", market.propid).Lv

    local castle_lv = self:get_castle_lv()
    if castle_lv < 10 then
        if id == 3 or id == 4 then return end
    elseif castle_lv < 15 then
        if id == 4 then return end
    end

    local total = extra[1]
    local free = extra[2]
    local nodes = extra[3]

    if total <= 0 then return end

    local node
    for k, v in pairs(nodes) do
        if v[ 1 ] == id then
            node = v
            break
        end
    end
    if not node then return end

    local mode  = node[1]
    local nfresh= node[2]
    local nbuy  = node[3]
    local combo = node[4]

    if free > 0 then
        total = total - 1
        free = free - 1
    else
        total = total - 1
        nbuy = nbuy + 1

        local coin = resmng.prop_resm_num[ nbuy ].RMB
        if self:get_res_num( resmng.DEF_RES_GOLD ) < coin then return end
        self:consume({{resmng.CLASS_RES, resmng.DEF_RES_GOLD, coin}}, 1, VALUE_CHANGE_REASON.RESOURCE_MARKET_PAY)
    end

    local nres = math.floor(resmng.prop_resm[ marketlv ].Conf[ mode ] * ( 1 + nfresh * 0.005 ) * ( combo + 1 ) + 0.5)
    nfresh = nfresh + 1

    self:add_bonus("mutex_award", {{"res", mode, nres}}, VALUE_CHANGE_REASON.BLACK_MARKET_BUY)
    reply_ok(self, "buy_res", combo )

    --任务
    task_logic_t.process_task(self, TASK_ACTION.MARKET_BUY_NUM, 2, 1)
    --周限时活动
    weekly_activity.process_weekly_activity(self, WEEKLY_ACTIVITY_ACTION.RES_MARKET, mode, nres)
    --运营活动
    operate_activity.process_operate_activity(self, OPERATE_ACTIVITY_ACTION.RESOURCE_MARKET, 1)
                
    extra[1] = total
    extra[2] = free

    node[2] = nfresh
    node[3] = nbuy
    node[4] = 0

    local rates = { [1] = 4000, [2] = 3000, [5] = 2000,  [10] = 1000 }
    for k, v in pairs(nodes) do
        local node = v
        local rate = math.random(1,10000)
        for k, v in pairs(rates) do
            rate = rate - v
            if rate <= 0 then
                combo = k - 1
                if combo > node[4] then
                    node[4] = combo
                end
                break
            end
        end
    end

    self:add_count( resmng.ACH_COUNT_BUY_RES, 1 )

    dumpTab(extra, "resource_buy")
    market.extra = extra

end

