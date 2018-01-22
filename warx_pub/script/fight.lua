module("fight", package.seeall)
--clean in crontab, every minute
gFightReports = gFightReports or {}

function init_arg_match()
    local t = {}
    for amode = 1, 4, 1 do
        local tt = {}
        t[amode] = tt
        for dmode = 1, 4, 1 do
            local ttt = {
                [1] = {"Atk_R", string.format("Atk%d_R", amode), string.format("AAtk%d_R",dmode), "Imp_R", string.format("Imp%d_R", amode), string.format("AImp%d_R", dmode)},
                [2] = {"Imm_R", string.format("Imm%d_R", dmode), string.format("DImm%d_R",amode)}
            }
            tt[ dmode] = ttt
        end
    end
    gArgMatch = t
end

init_arg_match()


local function _calc_atk(A, As, D, Ds)
    local amode = A.mode
    local dmode = D.mode

    A.hit = dmode

    local node = gArgMatch[ amode ][ dmode ]

    local atkR = 0
    for _, v in pairs(node[1]) do atkR = atkR + (A.ef[ v ] or 0) end

    atkR = (1 + atkR * 0.0001)

    local mul = 1 + atkR * 0.0001
    local total = 0
    for _, a in pairs(A.objs) do
        if a.num > 0 then
            total = total + a.Atk *a.num * mul
        end
    end
    return total
end


local function _apply_dmg(D, amode, total)
    local dmode = D.mode
    local node = gArgMatch[ amode ][ dmode ]

    local immR = 0
    for _, v in pairs(node[2]) do immR = immR + (D.ef[ v ] or 0) end
    immR = (1 + immR * 0.0001)

    local dmgAll = 0
    for _, d in pairs(D.objs) do
        if d.num > 0 then
            -- ############################ --
            local dmg = total * d.pow / D.pow
            dmg = dmg * (1-d.Imm * immR)
            -- ############################ --
            --print(string.format("amode=%d, dmode=%d, dmg=%f", amode, dmode, dmg))

            if dmg < 0 then dmg = 0 end

            local most = d.hpAll
            if dmg > most then dmg = most end

            d.dmg = (d.dmg or 0) + dmg
            dmgAll = dmgAll + dmg 
        end
    end
    return dmgAll
end


function _tower_attack(D, dmg)
    local rate = {0.25, 0.25, 0.25, 0.25}
    local sum = 0
    for dmode, d in pairs(D.arms) do
        if d.num > 0 then sum = sum + d.pow * rate[ dmode ] end
    end

    local total = 0
    for dmode, d in pairs(D.arms) do
        if d.num > 0 then
            local r = d.pow * rate[dmode] / sum
            total = total + _apply_dmg(d, 4, r * dmg )
        end
    end
    return total
end

function get_tower_dmg( A )
    local pow = 0
    local tl = A:get_build_function( 15 )
    local tr = A:get_build_function( 20 )
    if tl then pow = resmng.get_conf( "prop_build", tl.propid ).Param.Atk end
    if tr then pow = pow + resmng.get_conf( "prop_build", tr.propid ).Param.Atk end
    return pow
end


local function _attack(A, As, D, Ds, mode, rate)
    rate = rate or 1

    local amode = A.mode
    local dmode = D.mode

    A.hit = dmode

    local node = gArgMatch[ amode ][ dmode ]

    local atkR = 0
    local immR = 0

    for _, v in pairs(node[1]) do atkR = atkR + (A.ef[ v ] or 0) end
    for _, v in pairs(node[2]) do immR = immR + (D.ef[ v ] or 0) end

    atkR = (1 + atkR * 0.0001)
    immR = (1 + immR * 0.0001)

    local atkImm0 = 0
    local atkImmN = 0

    if mode == 0 then
        local k = "AtkImmCom_R"
        atkImm0 = D.ef[k] or 0
        k = string.format("AtkImmCom%d_R", amode)
        atkImmN = D.ef[k] or 0
    elseif mode ==  1 then
        local k = "AtkImmTac_R"
        atkImm0 = D.ef[k] or 0
        k = string.format("AtkImmTac%d_R", amode)
        atkImmN = D.ef[k] or 0
    end

    for _, a in pairs(A.objs) do
        if a.num > 0 then
            local atk = a.Atk * atkR * a.num * rate
            atk = atk * (1 - atkImm0 * 0.0001) * (1 - atkImmN * 0.0001)

            for _, d in pairs(D.objs) do
                if d.num > 0 then
                    -- ############################ --
                    local dmg = atk * d.pow / D.pow
                    dmg = dmg * (1-d.Imm * immR)
                    -- ############################ --

                    if As.is_player and Ds.is_player and ( not a.hero ) and ( not d.hero ) then
                        dmg = dmg * math.pow(1.2, a.Lv - d.Lv)
                    end

                    if dmg < 0 then dmg = 0 end

                    local most = d.hpAll + 1
                    if dmg > most then dmg = most end

                    if mode == 0 then 
                        a.mkdmg0 = (a.mkdmg0 or 0) + dmg
                    elseif mode == 1 then 
                        a.mkdmg1 = (a.mkdmg1 or 0) + dmg 
                    end

                    a.mkdmg = (a.mkdmg or 0) + dmg
                    d.dmg = (d.dmg or 0) + dmg

                end
            end
        end
    end
end


function _calc(As)
    local res = {0,0,0,0}
    local heros = {0,0,0,0}
    local total = 0
    for mode = 1, 4, 1 do
        local lives = 0
        local A = As.arms[mode]
        if A and A.num > 0 then
            -- xixue
            local dmgToHp0 = A.ef.DmgToHp0 or 0
            local dmgToHp1 = A.ef.DmgToHp1 or 0
            local hpR = (A.ef.Hp_R or 0) + (A.ef[ string.format( "Hp%d_R", mode ) ] or 0) + (A.ef.Def_R or 0) + (A.ef[ string.format( "Def%d_R", mode ) ] or 0) 

            for _, v in pairs(A.objs) do
                if v.num > 0 then
                    v.dmg = v.dmg or 0

                    local tohp = 0
                    if dmgToHp0 > 0 then tohp = tohp + (v.mkdmg0 or 0) * dmgToHp0 * 0.0001 end
                    if dmgToHp1 > 0 then tohp = tohp + (v.mkdmg1 or 0) * dmgToHp1 * 0.0001 end
                    v.dmg = v.dmg - tohp
                    if v.dmg < 0 then v.dmg = 0 end

                    -- ############################ --
                    if v.dmg > 1 then
                        local dead = v.dmg / (v.Hp * (1 + hpR * 0.0001))
                        v.num = v.num - dead
                        if v.num < 0 then v.num = 0 end
                    end
                    -- ############################ --

                    v.dmg = 0
                    v.mkdmg0 = 0
                    v.mkdmg1 = 0
                end

                if v.hero then heros[ mode ] = v.num end
                lives = lives + v.num
            end

            A.num = lives
            total = total + lives
        end
        res[mode] = math.ceil(lives)
    end
    return res, math.ceil(total), heros
end


local function _apply_dmg_buf(D, A)
    for mode, arm in pairs(D.arms) do
        if arm.num > 0 and arm.bufdmg then
            for k, v in pairs(arm.bufdmg) do
                --v = {count, total, amode, anode}
                if v[1] > 0 then
                    v[1] = v[1] - 1
                    local total = v[2]
                    local amode = v[3]
                    local anode = v[4]
                    local dmg = _apply_dmg(arm, amode, total)
                    anode.mkdmg = (anode.mkdmg or 0) + dmg
                end
            end
        end
    end
end


local function _apply_dmg_tower(D, A)
end

local _fight_seqs = {
        [1] = {3,1,4,2},
        [2] = {1,2,4,3},
        [3] = {2,3,4,1},
        [4] = {4,1,2,3},
    }

-- A, D = arms
-- first,buf dmg
-- next, tower dmg
-- last, force dmg
-- todo, about atk sequence
local function _round(A, D)
    for amode, a in pairs(A.arms) do
        local double = a.ef.ExtraAtk or 0

        if a.num > 0 then
            if amode == 4 then
                local rate = {0.05, 0.05, 0.05, 1}
                local sum = 0
                for dmode, d in pairs(D.arms) do
                    if d.num > 0 then sum = sum + d.pow * rate[ dmode ] end
                end

                for dmode, d in pairs(D.arms) do
                    if d.num > 0 then
                        local r = d.pow * rate[dmode] / sum
                        _attack(a, A, d, D, 0, r)
                        if double > 0 then _attack(a, A, d, D, 0, r * double * 0.0001) end
                    end
                end
            else
                local seq = _fight_seqs[ amode ]
                for _, dmode in ipairs(seq) do
                    local d = D.arms[ dmode ]
                    if d and d.num > 0 then
                        _attack(a, A, d, D, 0, 1)
                        if double > 0 then _attack(a, A, d, D, 0, 1 * double * 0.0001) end
                        break
                    end
                end
            end
        end

    end
end

-- 反击
local function _counter_attack(A, D)
    for amode, a in pairs(A.arms) do
        if a.ef.CounterAtk and a.ef.CounterAtk > 0 and a.num and a.num > 0 and a.dmg and a.dmg > 0 then
            local rate = {0.25, 0.25, 0.25, 0.25}
            local sum = 0
            for dmode, d in pairs(D.arms) do
                if d.num > 0 then sum = sum + d.pow * rate[ dmode ] end
            end

            for dmode, d in pairs(D.arms) do
                if d.num > 0 then
                    local r = d.pow * rate[dmode] / sum
                    r = r * a.ef.CounterAtk * 0.0001
                    _attack(a, A, d, D, 0, r)
                end
            end
        end
    end
end

local function _tactics(As, Ds, round, report, who)
    local fires = {}
    local flag = false
    for amode, A in pairs(As.arms) do
        if A.num > 0 and amode ~= 4 then
            if not A.tacTm then A.tacTm = 0 end
            local cd =  10 * (1 - (A.ef.TacticsCd_R or 0) * 0.0001)
            if round - A.tacTm >= cd then
                A.tacTm = round
                if (not A.ef.TacticsBlock) or (A.ef.TacticsBlock == 0) then
                    if _fight_seqs[ amode ][1] == A.hit or (A.ef.TacticsAll or 0) > 0 then

                        local D = Ds.arms[ A.hit ]
                        local k = string.format("TacticsAtk%d_R", amode)
                        local extra = (A.ef.TacticsAtk_R or 0) + (A.ef[ k ] or 0) 

                        flag = true
                        fires[ amode ] = D.mode
                        _attack(A, As, D, Ds, 1, 2 * (1 + extra * 0.0001))
                        table.insert(report, {round, 4, who, amode, "tactics"})

                        local more = A.ef.TacticsMore or 0
                        if more > 0 then
                            for _, D in pairs(Ds.arms) do
                                if D.num > 0 and D.mode ~= A.hit then
                                    _attack(A, As, D, Ds, 1, 2 * more * 0.0001 * (1 + extra * 0.0001))
                                end
                            end
                        end
                        --todo, trig other
                    end
                end
            end
        end
    end
    if flag then return fires end
end

local function _tactics_link(fires, As, Ds, round, report, who)
    local link_count = 0
    for amode, _ in pairs( fires ) do
        local ahero = As.heros[ amode ]
        if ahero and ahero.num > 0 then
            local acul = ahero.cul
            local aper = ahero.per
            for mode, bhero in pairs( As.heros ) do
                if mode ~= 4 and amode ~= mode and bhero.num > 0 then
                    local rate = 1500
                    if bhero.cul == acul then rate = rate + 750 end
                    if bhero.per == aper then rate = rate + 750 end
                    if math.random(1, 10000) < rate then
                        local A = As.arms[ mode ]
                        local D = Ds.arms[ A.hit ]
                        local k = string.format("TacticsAtk%d_R", mode)
                        local extra = (A.ef.TacticsAtk_R or 0) + (A.ef[ k ] or 0) 
                        _attack(A, As, D, Ds, 1, 2 * (1 + extra * 0.0001))
                        table.insert(report, {round, 5, who, amode, "tactics_link"})
                        link_count = link_count + 1
                    end
                end
            end
        end
    end

    --任务
    if link_count > 0 then
        if As.owner_pid >= 10000 then
            local owner = getPlayer( As.owner_pid )
            if owner then
                task_logic_t.process_task(owner, TASK_ACTION.BATTLE_LIANDONG, link_count)
            end
        end
    end
end


function _get_num(A)
    local res = {0,0,0,0}
    for mode = 1,4,1 do
        local arm = A.arms[ mode ]
        if arm then res[mode] = math.ceil(arm.num) end
    end
    return res
end

local function _all_dead(T)
    for _, v in pairs(T.arms) do
        if v.num > 0 then return false end
    end
    return true
end

vfunc_cond = {}
vfunc_cond["AND"] = function (A, As, Ds, ...)  -- A obj, D obj, A arms, D arms
    for _, v in pairs({...}) do
        if not do_cond(A, As, Ds, unpack(v)) then return false end
    end
    return true
end

vfunc_cond["OR"] = function (A, As, Ds, ...)  -- A obj, D obj, A arms, D arms
    for _, v in pairs({...}) do
        if do_cond(A, As, Ds, unpack(v)) then return true end
    end
end

-- A, self,
-- A attck D, B attack A
vfunc_cond["AMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    return A and A.mode == mode
end

vfunc_cond["DMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    for _, v in pairs(A.as) do
        if v == mode then return true end
    end
end

vfunc_cond["BMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    for _, v in pairs(A.ds) do
        if v == mode then return true end
    end
end


vfunc_cond["RATE"] = function (A, As, Ds, rate)
    return math.random(1,10000) < rate
end

function do_cond(A, As, Ds, Func, ...)
    if vfunc_cond[ Func ] then
       return vfunc_cond[ Func ](A, As, Ds, ...)
   else
       WARN("fight, do_cond, Func = %s", Func)
       return false
   end
end

function buff_check(buf, A, As, Ds)
    local cond = buf.cond
    if cond and #cond > 0 then
        return do_cond(A, As, Ds, unpack(cond))
    else
        return true
    end
end

function skill_check(skill, A, As, Ds)
    local cond = skill.cond
    if cond and #cond > 0 then
        return do_cond(A, As, Ds, unpack(cond))
    else
        return true
    end
end

vfunc_skill = {}

vfunc_skill[ "DmgBuf" ] = function (Target, hero, A, As, Ds, ratio, count)
    if A.mode == 4 then
        local rate = {0.05, 0.05, 0.05, 1}
        local sum = 0
        for dmode, d in pairs(Ds.arms) do
            if d.num > 0 then sum = sum + d.pow * rate[ dmode ] end
        end

        for dmode, D in pairs(Ds.arms) do
            if D.num > 0 then
                local r = D.pow * rate[dmode] / sum
                local dmg = _calc_atk(A, As, D, Ds) 
                dmg = dmg * ratio * r * 0.0001
                if not D.bufdmg then D.bufdmg = {} end
                table.insert(D.bufdmg, {count, dmg, A.mode, hero})
            end
        end
    else
        for k, v in pairs(A.as) do
            local D = Ds.arms[ v ]
            if D then
                local dmg = _calc_atk(A, As, D, Ds) 
                dmg = dmg * ratio * 0.0001
                if not D.bufdmg then D.bufdmg = {} end
                table.insert(D.bufdmg, {count, dmg, A.mode, hero})
            end
        end
    end
end


vfunc_skill[ "DmgBufMode" ] = function (Target, hero, A, As, Ds, mode, ratio, count)
    for k, v in pairs(A.as) do
        local D = Ds.arms[ v ]
        if D and D.mode == mode then
            local dmg = _calc_atk(A, As, D, Ds) 
            dmg = dmg * ratio * 0.0001
            if not D.bufdmg then D.bufdmg = {} end
            table.insert(D.bufdmg, {count, dmg, A.mode, hero})
        end
    end
end


function do_skill_fire(Target, hero, A, As, Ds, Func, ...)
    if vfunc_skill[ Func ] then
        vfunc_skill[ Func ](Target, hero, A, As, Ds, ...)
    end
end

function skill_fire(skill, hero, A, As, Ds)
    local effect = skill.Effect
    if effect then
        for _, e in pairs(effect) do
            do_skill_fire(skill.Target or "A", hero, A, As, Ds, unpack(e))
        end
    end
end

local function _launch_skills(As, Ds, round, report, who)
    for _, A in pairs(As.arms) do
        for _, obj in pairs(A.objs) do
            if obj.hero then
                if obj.num > 0 then
                    for _, v in pairs(obj.skills) do
                        local skill = resmng.prop_skill[v]
                        if skill and skill.Type == 1 and skill_check(skill, A, As, Ds) then
                            skill_fire(skill, obj, A, As, Ds)
                            --table.insert(report, {round, 3, who, A.mode, obj.id, skill.ID, "skills"})
                        end
                    end
                end
            end
        end
    end
end

local function _launch_skill(As, Ds, round, report, who)
    for _, A in pairs(As.arms) do
        for _, obj in pairs(A.objs) do
            if obj.hero and obj.num > 0 then
                local skill = resmng.prop_skill[obj.skill]
                if skill and skill.Type == 0 and skill_check(skill, A, As, Ds) then
                    local rate = math.random(1, 100)
                    if (obj.fit_per and rate <= 23) or rate <= 15 then
                        skill_fire(skill, obj, A, As, Ds)
                        table.insert(report, {round, 2, who, A.mode, obj.id, skill.ID, "skill"})
                    end
                end
            end
        end
    end
end

function do_buf_dec(bs)
    local ns = {}
    local chg = false
    for _, b in pairs(bs) do
        b[2] = b[2] - 1
        if b[2] > 0 then
            table.insert(ns, b)
        else
            chg = true
            --INFO("BUF, del, id=%d", b[1].ID)
        end
    end
    return ns, chg
end

local _mt_eff = { __index = function (tab, key) return 0 end }
function do_buf_recalc(bs, A, As, Ds)
    local es = {}
    for _, v in pairs(bs) do
        local b = v[1]
        if b then
            if buff_check(b, A, As, Ds) then
                for key, val in pairs(b.Effect or {}) do
                    es[ key ] = (es[key] or 0) + val
                end
            end
        end
    end
    return setmetatable(es, _mt_eff)
end

function get_hero(sn)
    local what = type(sn)
    if what == "table" then
        return sn
    elseif what == "string" then
        local idx, pid = string.match(sn, "(%d+)_(%d+)")
        local p = getPlayer(tonumber(pid))
        if p then
            return p:get_hero(tonumber(idx))
        end
    end
end


function _match(As, Ds)
    for _, C in pairs({As, Ds}) do
        for mode, arm in pairs(C.arms) do
            arm.as = {}
            arm.ds = {}
        end
    end

    for amode, A in pairs(As.arms) do
        if A.num > 0 then
            local seq = _fight_seqs[ amode ]
            for _, dmode in pairs(seq) do
                local D = Ds.arms[ dmode ]
                if D and D.num > 0 then
                    table.insert(A.as, dmode)
                    table.insert(D.ds, amode)
                    if amode ~= 4 then break end
                end
            end
        end
    end

    for dmode, D in pairs(Ds.arms) do
        if D.num > 0 then
            local seq = _fight_seqs[ dmode ]
            for _, amode in pairs(seq) do
                local A = As.arms[ amode ]
                if A and  A.num > 0 then
                    table.insert(D.as, amode)
                    table.insert(A.ds, dmode)
                    if dmode ~= 4 then break end
                end
            end
        end
    end
end


fight.pvp = function(action, A0, D0)
    c_tick(0)

    local total = 0
    if not D0  then
        A0.win = 1
        return true, 0
    end

    local fid = A0.eid
    A0.fid = fid
    D0.fid = fid

    if A0.notify_owner then A0:notify_owner() end
    if D0.notify_owner then D0:notify_owner() end

    if A0.save then A0:save() end
    if D0.save then D0:save() end

    local A = init_troop(A0)
    local D = init_troop(D0)

    local propida = A0.owner_propid

    local atker = get_ety( A0.owner_eid )
    local defer = get_ety( D0.owner_eid )
    
    if is_ply( defer ) then
        Rpc:be_attacked( defer )
    end

    if not propida then
        if atker then propida = atker.propid end
    end

    local Target = get_ety( A0.target_eid )
    if Target then
        propidd = Target.propid
    end
    if not Target and action == TroopAction.SiegeTaskNpc then
        propidd = D0.owner_propid
    end

    LOG("fight, action=%s, owner_eidA=%d, target_eidA=%d, troopidA=%d, owner_eidD=%d, troopidD=%d", action or 0, A0.owner_eid or 0, A0.target_eid or 0, A0._id or 0, D0.owner_eid or 0, D0._id or 0)

    local report = {{0,0,A0.eid, A0.owner_eid, A0.target_eid, A.heroid, D.heroid, A0.dx, A0.dy, propida, propidd, A0.sx, A0.sy }}
    table.insert(report, {0, 1, _get_num(A), _get_num(D), A.herohp, D.herohp })

    local count_round = 30
    if action == TroopAction.SiegePlayer then
        if math.abs( atker:get_castle_lv() - defer:get_castle_lv() ) >= 5 then count_round = 16 end
    end

    
    local round = 0
    local tutter_dmg = 0
    for i = 1, count_round, 1 do
        round = round + 1
        _match(A, D)

        if i == 1 then
            _launch_skills(A, D, i, report, 1)
            _launch_skills(D, A, i, report, 2)
        end

        if (i - 4) % 6 == 0 then
            _launch_skill(A, D, i, report, 1)
            _launch_skill(D, A, i, report, 2)
        end

        refresh_buf(A, D)
        refresh_buf(D, A)

        for _, C in pairs({A, D}) do
            for mode, arm in pairs(C.arms) do
                local pow = 0
                local hpR = (arm.ef.Hp_R or 0) + (arm.ef[ string.format( "Hp%d_R", mode ) ] or 0) + (arm.ef.Def_R or 0) + (arm.ef[ string.format( "Def%d_R", mode ) ] or 0) 
                for _, obj in pairs(arm.objs) do
                    if obj.num > 0 then
                        obj.pow = obj.num * obj.Pow
                        pow = pow + obj.pow
                        obj.hpAll = obj.Hp * (1 + hpR * 0.0001) * obj.num
                    end
                end
                arm.pow = pow
            end
        end

        if i == 1 then
            if is_ply( defer ) and D0.action == TroopAction.DefultFollow then
                local pow = get_tower_dmg(defer)
                if pow and pow > 0 then
                    pow = _tower_attack( A, pow )
                    if pow > 0 then
                        pow = math.ceil( pow )
                        --D0.arms[ defer.pid ].kill_soldier[ 0 ] = pow
                        tutter_dmg = pow
                    end
                end
            end
        end

        _apply_dmg_buf(A, D)
        _apply_dmg_buf(D, A)
        _apply_dmg_tower(D, A)

        _round(A, D)
        _round(D, A)

        local fires = false

        fires = _tactics(A, D, i, report, 1)
        if fires then _tactics_link(fires, A, D, i, report, 1) end

        fires = _tactics(D, A, i, report, 2)
        if fires then _tactics_link(fires, D, A, i, report, 2) end

        _counter_attack(A, D)
        _counter_attack(D, A)

        local ta, la, ha = _calc(A)  --total, live, hero
        local td, ld, hd = _calc(D)
        table.insert(report, {i, 1, ta, td, ha, hd })

        if la == 0 or ld == 0 then break end
    end

    --dumpTab(report, "fight")

    local losts = {round, -1,}

    local lostA, liveA, make_dmgA, dead_numA, dead_lvlA = fight_status(A) 
    local lostD, liveD, make_dmgD, dead_numD, dead_lvlD = fight_status(D) 


    --print( lostA, liveA, make_dmgA, dead_numA, dead_lvlA )
    --print( lostD, liveD, make_dmgD, dead_numD, dead_lvlD )

    if tutter_dmg > 0 then
        make_dmgD = make_dmgD + tutter_dmg

        --local arm = D0.arms[ defer.pid ]
        --arm.mkdmg = ( arm.mkdmg or 0 ) + tutter_dmg

        local pid = defer.pid
        local obj = { id = 0, mode = 0, pid = pid, num = 1, num0 = 1, Pow = 1, mkdmg = tutter_dmg, pids = { [ pid ] = { num0 = 1, mkdmg = tutter_dmg } } }
        D.arms[ 0 ] = { mode = 0, num = 1, objs = { [0] = obj } }
    end


    A0.mkdmg = lostD
    D0.mkdmg = lostA
    A0.lost = lostA
    D0.lost = lostD

    table.insert(losts, lostA)
    table.insert(losts, lostD)
    table.insert(report, losts)

    local ispvp = ( A.is_player and D.is_player )

    calc_kill( action, A, A0, make_dmgA, lostD, dead_numD, dead_lvlD, ispvp ) 
    calc_kill( action, D, D0, make_dmgD, lostA, dead_numA, dead_lvlA, ispvp )

    local win = 0

    if lostA <= lostD then win = 1 else win = 2 end
    if liveA == 0 then win = 2 elseif liveD == 0 then win = 1 end

    table.insert(report, { round, -2, win=win } )

    if win==1 then
        A0.win = 1
        D0.win = nil
    else
        A0.win = nil
        D0.win = 1
    end
    
    local pid = 0
    local uid = 0
    local atker = get_ply(A0.owner_eid)
    if atker then
        pid = atker.pid
        uid = atker.uid
    end
    
    if action == TroopAction.SiegeTaskNpc then
        Rpc:battle(atker, A0.eid, A0.owner_eid, A0.target_eid, A0.owner_pid, A0.owner_uid)
    else
        Rpc:around0(A0.target_eid, "battle", A0.eid, A0.owner_eid, A0.target_eid, pid, uid)
    end
    gFightReports[ A0.eid ] = {gTime, report}

    ---------replay
    local replay_id = get_replay_id()
    gPendingInsert.replay[ replay_id ] = { gTime, report }
    A0.replay_id = replay_id

    return (win == 1), round
end


function get_troop_buf(At)
    local args = {
        "Atk_R", "Atk1_R", "Atk2_R", "Atk3_R", "Atk4_R",
        "Def_R", "Def1_R", "Def2_R", "Def3_R", "Def4_R",
        "Imp_R", "Imp1_R", "Imp2_R", "Imp3_R", "Imp4_R",
        "Hp_R", "Hp1_R", "Hp2_R", "Hp3_R", "Hp4_R",
        "CountSoldier", "CountSoldier_A" 
    }
    local buf = {}
    if At.owner_pid and At.owner_pid >= 10000 then
        local A = getPlayer(At.owner_pid)
        if A then
            --人物单独的buff
            local ef = A._ef
            for k, v in pairs(args) do
                if ef[ v ] and ef[ v ] > 0 then
                    if buf[ v ] == nil then buf[ v ] = 0 end
                    buf[ v ] = buf[ v ] + ef[ v ] 
                end
            end
            --军团的buff
            local ef_union = A:get_union_ef()
            for k, v in pairs(args) do
                if ef_union[ v ] and ef_union[ v ] > 0 then
                    if buf[v] == nil then buf[v] = 0 end
                    buf[ v ] = buf[ v ] + ef_union[ v ] 
                end
            end
            --服务器buff
            local ef_gs = kw_mall.gsEf or {}
            for k, v in pairs(args) do
                if ef_gs[ v ] and ef_gs[ v ] > 0 then
                    if buf[v] == nil then buf[v] = 0 end
                    buf[ v ] = buf[ v ] + ef_gs[ v ] 
                end
            end
        end
    end
    return buf
end

--At = {
--    name = "",
--    pid = 10001,
--    owner_pid = 10001,
--    arms = {
--        [pidA] = {
--            pid = pidA,
--            live_soldier = { [1001] = 50, [2001] = 100 },
--            dead_soldier = { [1001] = 30, [2001] = 300 },   -- set by fight
--            hurt_soldier = { [1001] = 20, [3001] = 400 },   -- change from dead_soldier
--            heros = { heroidA, heroidB, heroidC, heroidD }, -- hero = heromng.get_hero_by_id( heroidA )
--            mkdmg = 100001,                                 -- set by fight
--            lost = 10000,                                   -- set by fight
--        },
--        [pidB] = {
--        
--        }
--    }
--}
--

function hero_capture(At, Dt)
    local pidA = At.owner_pid
    if not pidA then return end
    if pidA == 0 then return end
    local armA = At.arms[ pidA ]
    if not armA then return end

    local pidD = Dt.owner_pid
    if not pidD then return end
    if pidD == 0 then return end
    local armD = Dt.arms[ pidD ]
    if not armD then return end

    local A = getPlayer( pidA )
    local D = getPlayer( pidD ) 
    if not A or A:get_castle_lv() < 10 then return end
    if not D or D:get_castle_lv() < 10 then return end

    local counter = 0
    local hsDeadD = {}
    local hsLiveD = {}
    for _, hero in pairs(armD.heros or {}) do
        if hero ~= 0 then
            local h = heromng.get_hero_by_uniq_id(hero)
            if h then
                if h.hp <= 0 then table.insert(hsDeadD, h) else table.insert(hsLiveD, h) end 
                local ef = h:get_ef_after_fight()
                if ef then counter = counter + (ef.CounterCaptive or 0) end
               -- counter = counter + h:get_hero_equip_attr("CounterCaptive", "r")
            end
        end
    end
    if #hsDeadD < 1 and #hsLiveD < 1 then return end
    
    local plD = getPlayer(pidD)
    counter = counter + plD:get_num("CounterCaptive")

    local captive = 0
    local hsDeadA = {}
    local hsLiveA = {}
    for _, hero in pairs(armA.heros or {}) do
        if hero ~= 0 then
            local h = heromng.get_hero_by_uniq_id(hero)
            if h then
                if h.hp <= 0 then table.insert(hsDeadA, h) else table.insert(hsLiveA, h) end 
                local ef = h:get_ef_after_fight()
                if ef then captive = captive + (ef.Captive or 0) end
                --captive = captive + h:get_hero_equip_attr("Captive", "r")
            end
        end
    end
    if #hsDeadA < 1 and #hsLiveA < 1 then return end

    local plA = getPlayer(pidA)
    captive = captive + plA:get_num("Captive")

    if captive <= counter then return end
    if math.random(1,10000) <= captive - counter then 
        local heroD = false
        if #hsDeadD > 0 then heroD = hsDeadD[ math.random(1, #hsDeadD) ]
        else heroD = hsLiveD[ math.random(1, #hsLiveD) ] end

        local heroA = false
        if #hsLiveA > 0 then heroA = hsLiveA[ math.random(1, #hsLiveA) ]
        else heroA = hsDeadA[ math.random(1, #hsDeadA) ] end

        return heroA, heroD
    end
end


function clean_report()
    local dels = {}
    for k, v in pairs(gFightReports) do
        if gTime - v[1] > 60 then
            table.insert(dels, k)
        end
    end
    for _, v in pairs(dels) do
        gFightReports[ v ] = nil
    end
end


-- new_buf_arangement
-- new_buf_arangement
-- new_buf_arangement
function effect_attach(dst, src) -- attach src to dst
    for k, v in pairs(src or {}) do
        dst[ k ] = (dst[ k ] or 0) + v
    end
end

function effect_detach(src, dst) -- detach dst from src
    for k, v in pairs(dst or {}) do
        src[ k ] = (src[ k ] or 0) - v
    end
end

-- buf = {bufid, count, effect}
function do_add_buf(arm, prop, count)
    local id = prop.ID
    for k, v in pairs( arm.buf or {} ) do
        if v[1] == id then
            v[2] = count
            return
        end
    end
    table.insert(arm.buf, {prop.ID, count, prop.Value})
    effect_attach(arm.ef, prop.Value)
end

function refresh_buf(T)
    for _, arm in pairs(T.arms) do
        local dels = {}
        for k, v in ipairs(arm.buf) do
            v[2] = v[2] - 1
            if v[2] < 0 then
                effect_detach(arm.ef, v[3])
                table.insert(dels, 1, k)
            end
        end
        for _, idx in ipairs(dels) do
            table.remove(arm.buf, idx)
        end
    end
end


vfunc_skill[ "AddBuf_A" ] = function (Target, hero, A, As, Ds, bufid, count)
    if count <= 0 then return end
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        do_add_buf(A, buf, count)
    end
end

vfunc_skill[ "AddBuf_AS" ] = function (Target, hero, A, As, Ds, bufid, count)
    if count <= 0 then return end
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        for _, v in pairs(As.arms) do
            do_add_buf(v, buf, count)
        end
    end
end

vfunc_skill[ "AddBuf_D" ] = function (Target, hero, A, As, Ds, bufid, count)
    if count <= 0 then return end
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        for k, v in pairs(A.as) do
            local D = Ds.arms[ v ]
            if D then
                do_add_buf(D, buf, count)
            end
        end
    end
end

vfunc_skill[ "AddBuf_DS" ] = function (Target, hero, A, As, Ds, bufid, count)
    if count <= 0 then return end
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        for _, v in pairs(Ds.arms) do
            do_add_buf(v, buf, count)
        end
    end
end

vfunc_skill[ "AddBuf_B" ] = function (Target, hero, A, As, Ds, bufid, count)
    if count <= 0 then return end
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        for k, v in pairs(A.ds) do
            local D = Ds.arms[ v ]
            if D then
                do_add_buf(D, buf, count)
            end
        end
    end
end

vfunc_skill[ "AddBuf_BS" ] = function (Target, hero, A, As, Ds, bufid, count)
    if count <= 0 then return end
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        for _, v in pairs(Ds.arms) do
            do_add_buf(v, buf, count)
        end
    end
end


vfunc_skill[ "AddBuf" ] = function (Target, hero, A, As, Ds, bufid, count)
    if count <= 0 then return end
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        if Target == "A" then
            do_add_buf(A, buf, count)

        elseif Target == "AS" then
            for _, v in pairs(As.arms) do
                do_add_buf(v, buf, count)
            end

        elseif Target == "D" then
            for k, v in pairs(A.as) do
                local D = Ds.arms[ v ]
                if D then
                    do_add_buf(D, buf, count)
                end
            end

        elseif Target == "DS" then
            for _, v in pairs(Ds.arms) do
                do_add_buf(v, buf, count)
            end

        elseif Target == "B" then
            for k, v in pairs(A.ds) do
                local D = Ds.arms[ v ]
                if D then
                    do_add_buf(D, buf, count)
                end
            end
        elseif Target == "BS" then
            for _, v in pairs(Ds.arms) do
                do_add_buf(v, buf, count)
            end
        end
    end
end

-- clean : T.win, T.arms.dead_soldier, mkdmg, lost
function init_troop(T)
    local ef = {}
    local efs = {
    "Hp_R", "Hp1_R", "Hp2_R", "Hp3_R", "Hp4_R",
    "Def_R", "Def1_R", "Def2_R", "Def3_R", "Def4_R",
    "TacticsAtk_R", "TacticsAtk1_R", "TacticsAtk2_R", "TacticsAtk3_R", "TacticsAtk4_R",
    "TacticsCd_R", "TacticsBlock", "TacticsAll", "TacticsMore",
    "ExtraAtk", "VampireAtk", "CounterAtk" }

    local owner = false
    if T.owner_pid >= 10000 then
        local p = getPlayer(T.owner_pid)
        if p then
            owner = p
            local ef_ply = p._ef
            local ef_union = p:get_union_ef()
            local ef_gs = kw_mall.gsEf or {}
            for _, amode in pairs(gArgMatch) do
                for _, dmode in pairs(amode) do
                    for _, part in pairs(dmode) do
                        for _, k in pairs(part) do
                            local v = get_num_by(k, ef_ply, ef_union, ef_gs)
                            if v ~= 0 then
                                ef[ k ] = v
                            end
                        end
                    end
                end
            end

            for k, v in pairs( efs ) do
                local val = get_num_by( v, ef_ply, ef_union, ef_gs )
                if val ~= 0 then
                    ef[ v ] = ( ef[ v ] or 0 ) + val
                end
            end
        end
    end

    if T.ef_extra then
        for k, v in pairs( T.ef_extra ) do
            ef[ k ] = ( ef[ k ] or 0 ) + v
        end
    end
    
    local t = {
        num=0, 
        arms={
            {mode=1, num=0, objs={}, ef=copyTab(ef), buf={}},
            {mode=2, num=0, objs={}, ef=copyTab(ef), buf={}},
            {mode=3, num=0, objs={}, ef=copyTab(ef), buf={}},
            {mode=4, num=0, objs={}, ef=copyTab(ef), buf={}},
        },
        heroid = {0,0,0,0},
        herohp = {0,0,0,0},
        heros = {},
        owner_pid = T.owner_pid,
        is_player = false
    }

    T.win = nil
    for pid, arm in pairs(T.arms) do
        arm.dead_soldier = {}
        arm.kill_soldier = {}
        arm.mkdmg = 0
        arm.lost = 0
        arm.amend = nil
        
        local kill = {0,0,0,0}
        for id, num in pairs(arm.live_soldier or {}) do
            if num > 0 then
                local prop = resmng.prop_arm[ id ]
                if prop then
                    kill[ id ] = 0
                    local mode = prop.Mode
                    local node_a = t.arms[ mode ]
                    local objs = node_a.objs
                    local node = objs[ id ]
                    if not node then
                        node = { id = id, mode=mode, num = 0, Atk = prop.Atk, Imm = prop.Imm, Lv = prop.Lv, Hp = prop.Hp, Pow = prop.Pow, pids = {} }
                        objs[ id ] = node
                    end
                    node.num = node.num + num
                    node.num0 = node.num
                    node.pids[ pid ] = { num0 = num }
                    node_a.num = node_a.num + num
                    if pid >= 10000 then 
                        t.is_player = true 
                        player_t.mark_action_by_pid( pid, player_t.recalc_pow_arm )
                        player_t.mark_action_by_pid( pid, player_t.recalc_food_consume )
                    end
                end
            end
        end

        for mode, hid in pairs(arm.heros or {}) do
            if hid ~= 0 then
                local h = heromng.get_fight_attr(hid)
                if h and h.num > 0 then 
                    if t.arms[ mode ] then
                        local node_a = t.arms[ mode ] 
                        local objs = node_a.objs or {}
                        if not objs[ mode ] then
                            t.heroid[ mode ] = h.id
                            t.herohp[ mode ] = h.num
                            t.heros[ mode ] = h

                            local node = { id = hid, mode=mode, num = h.num, Atk = h.prop.Atk, Imm = h.prop.Imm, Lv = h.prop.Lv, Hp = h.prop.Hp, Pow = h.prop.Pow, pids = {}, fit_per = h.fit_per, skill=h.skill, skills=h.skills }
                            node.num0 = node.num
                            node.hero = hid
                            node.cul = h.cul
                            node.per = h.per
                            objs[ mode  ] = node

                            t.heroid[ mode ] = h.id
                            t.herohp[ mode ] = h.num
                            t.heros[ mode ] = node

                            node.pids[ pid ] = { num0 = h.num }
                            node_a.num = node_a.num + node.num
                            if pid == 0 then 
                                t.arms[ mode ].ef = copyTab( h.ef ) 
                            elseif pid >= 10000 then
                                hero_t.gPendingRecalcPow[ hid ] = 1

                                local hero = heromng.get_hero_by_uniq_id( hid )
                                if hero then
                                    hero_t.mark_recalc( hero )
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return t
end

function split( AS, count, total, key, nkey )
    -- a1[ key ] + a2[ key ] + a3[ key ] + ... + an[ key ] = total, share the count [ nkey ]
    for _, A in pairs( AS ) do
        local c = A[ key ]
        if c > 0 and total > 0 and count > 0 then
            local n
            if c >= total then
                n = count
                count = 0
                total = 0
            else
                n = math.ceil( count * c / total )
                if n > count then n = count end
            end
            count = count - n
            total = total - c
            A[ nkey ] = n
        else
            A[ nkey ] = 0
        end
    end
    return
end

function split2( AS, count, total, key )
    -- a1[ key ] + a2[ key ] + a3[ key ] + ... + an[ key ] = total, share the count [ nkey ]
    local res = {}
    if total > 0 and count > 0 then
        for id, A in pairs( AS ) do
            local c = A[ key ]
            if c > 0 then
                local n
                if c >= total then
                    n = count
                    count = 0
                    total = 0
                else
                    n = math.ceil( count * c / total )
                    if n > count then n = count end
                end
                count = count - n
                total = total - c
                res[ id ] = n
            else
                res[ id ] = 0
            end
        end
    end
    return res
end


-- return lost_pow, live_num, make_dmg, dead_num, dead_lvl
function fight_status(T)
    local lost_pow = 0
    local live_num = 0
    local make_dmg = 0
    local dead_num = 0
    local dead_lvl = {}

    for mode, arm in pairs(T.arms) do
        for _, obj in pairs(arm.objs) do
            obj.mkdmg = math.ceil( obj.mkdmg or 0 )
            local dead = 0
            if obj.hero then
                dead = obj.num0 - obj.num
                if T.is_player and dead > 0 then
                    local h = heromng.get_hero_by_uniq_id(obj.hero)
                    if h then 
                        local lost = math.ceil( dead * h.max_hp )
                        if lost > h.hp then lost = h.hp end
                        h.lost = lost
                        h.hp = h.hp - lost
                        if h.hp < 0 then h.hp = 0 end
                        if h.hp > h.max_hp then h.hp = h.max_hp end
                    end
                end
                if obj.num > 0 then live_num = live_num + 1 end

            else
                obj.num = math.ceil(obj.num)
                dead = obj.num0 - obj.num
                dead_num = dead_num + dead
                
                local lv = obj.Lv
                if not dead_lvl[ lv ] then dead_lvl[ lv ] = dead 
                else dead_lvl[ lv ] = dead_lvl[ lv ] + dead end

                live_num = live_num + obj.num
            end

            lost_pow = lost_pow + obj.Pow * dead
            make_dmg = make_dmg + obj.mkdmg
        end
    end
    return math.ceil(lost_pow), live_num, make_dmg, dead_num, dead_lvl
end


function sort_func( A, B ) 
    if A[3] ~= B[3] then
        return A[3] < B[3]
    else
        return A[1] < B[1]
    end
end


function rage(troop, D)
   -- if not is_ply(D) then return end
    local weights = {}

    local parts = {
        {0.5, 0.5, 0, 0},           -- < 10
        {0.33, 0.33, 0.33/5, 0},    -- < 15
        {0.25, 0.25, 0.25/5, 0.25/20 }
    }

    local erate = { 
        {1, 1, 0.2, 0.05}, 
        {1, 1, 0.2, 0.05}, 
        {5, 5, 1, 0.25}, 
        {20, 20, 4, 1} 
    }

    local rage_lv = Gather_Level

    local owner = getPlayer( troop.owner_pid )
    local ef_u = owner:get_union_ef()
    local ef_t = troop:get_ef()
    local ef_gs = kw_mall.gsEf or {}

    for pid, arm in pairs(troop.arms) do
        local total = 0
        for id, num in pairs(arm.live_soldier) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                total = total + (conf.Weight or 0) * num
            end
        end
        local ply = getPlayer( pid )
        local count_weight_r = 0
        if ply then 
            local r1 = get_num_by( "CountWeight_R", ply._ef, ef_u, ef_t, ef_gs) 
            total = total * ( 1 + r1 * 0.0001 )

            local r2 = get_num_by( "PlunderCount_R", ply._ef, ef_u, ef_t, ef_gs ) 
            total = total * ( 1 + r2 * 0.0001 )
        end
        total = math.floor( total * 0.5 )
        if total > 0 then
            table.insert(weights, {pid, total, arm.tm_join or pid })
        end
    end
    table.sort( weights, sort_func )

    local haves = D:get_res_over_store()

    local farms = D:get_farms()
    local result = {}

    local d_castle = D:get_castle_lv()

    for _, v in pairs(weights) do
        local needs = {0,0,0,0}
        local rages = {0,0,0,0}

        local pid = v[1]
        result[ pid ] = rages

        local ply = getPlayer( pid )
        if ply then
            local a_castle = ply:get_castle_lv()
            local part = true
            if a_castle < 10 then part = parts[ 1 ]
            elseif a_castle < 15 then part = parts[ 2 ]
            else part = parts[ 3 ] end

            for mode = 1, 4, 1 do
                needs[ mode ] = v[2] * part[ mode ]
            end

            for mode = 1, 4, 1 do
                if d_castle >= rage_lv[ mode ] and needs[ mode ] > 0 then
                    local need = needs[ mode ]
                    if haves[ mode ] >= need then
                        D:do_dec_res(mode, need, VALUE_CHANGE_REASON.RAGE)
                        rages[ mode ] = need
                        haves[ mode ] = haves[ mode ] - need
                        need = 0
                    elseif haves[mode] > 0 then
                        D:do_dec_res(mode, haves[mode], VALUE_CHANGE_REASON.RAGE)
                        need = need - haves[ mode ]
                        rages[ mode ] = haves[ mode ]
                        haves[ mode ] = 0
                    end
                    needs[ mode ] = need

                    if need > 0 then
                        local class = BUILD_CLASS.RESOURCE
                        local max_seq = BUILD_MAX_NUM[class] and BUILD_MAX_NUM[class][mode]
                        for seq = 1, max_seq, 1 do
                            local build_idx = D:calc_build_idx(class, mode, seq)
                            local build = D:get_build(build_idx)
                            if not build then break end
                            local get = build:res_reap_some(need)
                            if get > 0 then 
                                need = need - get 
                                rages[ mode ] = rages[ mode ] + get
                                if need == 0 then break end
                            end
                        end
                    end
                    needs[ mode ] = need
                end
            end

            for nmode, need in pairs(needs) do
                if need > 0 then
                    for hmode, have in pairs(haves) do
                        if have > 0 and d_castle >= rage_lv[ hmode ] then
                            local hnum = math.floor(need * erate[ nmode ][ hmode ])
                            if have > hnum then
                                haves[ hmode ] = haves[ hmode ] - hnum
                                rages[ hmode ] = rages[ hmode ] + hnum
                                need = 0
                                D:do_dec_res(hmode, hnum, VALUE_CHANGE_REASON.RAGE)
                            else
                                haves[ hmode ] = 0
                                rages[ hmode ] = rages[ hmode ] + have
                                need = need - math.floor(have * erate[ hmode ][ nmode ])
                                D:do_dec_res(hmode, have, VALUE_CHANGE_REASON.RAGE)
                            end
                        end
                        needs[ nmode ] = need
                        if need <= 0 then break end
                    end

                    if need > 0 then
                        while #farms > 0 and need > 0 do
                            local farm = farms[1] 
                            local hmode = farm.mode
                            local hnum = need * erate[ nmode ][ hmode ]
                            if a_castle >= rage_lv[ hmode ] and d_castle >= rage_lv[ hmode ] then
                                local get = farm:res_reap_some(hnum)
                                if get > 0 then
                                    if get >= hnum then
                                        rages[ hmode ] = rages[ hmode ] + hum
                                        need = 0
                                        break
                                    else
                                        rages[ hmode ] = rages[ hmode ] + get
                                        need = need - get * erate[ hmode ][ nmode ]
                                        table.remove(farms, 1)
                                    end
                                else
                                    table.remove(farms, 1)
                                end
                            end
                        end
                    end
                end
            end

        end
    end

    local gets = {}
    for pid, rages in pairs(result) do
        local its = {}
        for mode, num in pairs(rages) do
            if num > 0 then
                table.insert(its, {"res", mode, math.floor(num)})
            end
        end
        if #its > 0 then gets[ pid ] = its end
    end

    return gets
end

function calc_kill(action, troop, troop0, make_dmg, lost_powD, kill_num, kill_lvl, ispvp)
    --if make_dmg < 1 then return end

    LOG( "calc_kill, make_dmg=%s, lost_powD=%s, kill_num=%s", make_dmg, lost_powD, kill_num )
    --dumpTab( troop.arms, "calc_kill" )
    for _, arm in pairs( troop.arms or {} ) do
        for id, obj in pairs( arm.objs or {} ) do
            split( obj.pids, obj.num, obj.num0, "num0", "num" )
            split( obj.pids, obj.mkdmg, obj.num0, "num0", "mkdmg" )
        end
    end

    local statis = {}
    local total = 0
    for _, arm in pairs( troop.arms or {} ) do
        for id, obj in pairs( arm.objs or {} ) do
            for pid, ply in pairs( obj.pids or {} ) do
                total = total + ply.mkdmg
                local node = { pid = pid, id = id, live = ply.num, dead = ply.num0 - ply.num, mkdmg = ply.mkdmg, pow = obj.Pow }
                table.insert( statis, node )
            end
        end
    end

    split( statis, lost_powD, total, "mkdmg", "mkdmg" )
    split( statis, kill_num, lost_powD, "mkdmg", "kill" )

    --dumpTab( statis, "calc_kill_result" )

    local result = {}
    for _, v in pairs( statis ) do
        local pid = v.pid
        local node = result[ pid ]
        if not node then
            node = { pid = pid, mkdmg = 0, nkill = 0, ndead = 0, lost = 0, live={}, dead={}, kill={} }
            result[ pid ] = node
        end
        if v.id > 4 then
            node.live[ v.id ] = v.live 
            node.dead[ v.id ] = v.dead
            node.ndead = node.ndead + v.dead
        end

        node.kill[ v.id ] = v.kill
        node.nkill = node.nkill + v.kill
        node.mkdmg = node.mkdmg + v.mkdmg
        node.lost = node.lost + v.dead * v.pow
    end

    for pid, node in pairs( result ) do
        local arm = troop0.arms[ pid ] 
        if arm then
            arm.live_soldier = node.live
            arm.dead_soldier = node.dead
            arm.kill_soldier = node.kill
            arm.mkdmg = node.mkdmg
            arm.lost = node.lost

            if pid >= 10000 then
                local p = getPlayer( pid )
                if p then
                    --local action = troop0.action % 100

                    if ispvp and ( not ( action == TroopAction.LostTemple or action == TroopAction.SiegeNpc ) ) then
                        p:add_count( resmng.ACH_COUNT_KILL, node.nkill )
                        p:add_count( resmng.ACH_COUNT_KILL_POW, node.mkdmg )

                        rank_mng.add_data(4, pid, { p:get_count( resmng.ACH_COUNT_KILL) } )
                        local u = p:get_union()
                        if u then
                            u.kill = ( u.kill or 0 ) + node.nkill
                            rank_mng.add_data(6, p.uid, {u.kill})
                        end
                        task_logic_t.process_task(p, TASK_ACTION.DEAD_SOLDIER, node.ndead)
                    end

                    if ispvp then
                        for lv, num in pairs( kill_lvl or {} ) do
                            local n = math.floor( ( node.nkill / kill_num ) * num )
                            if n > 0 then
                                p:add_count(resmng["ACH_TASK_KILL_SOLDIER"..lv], n)
                                task_logic_t.process_task(p, TASK_ACTION.KILL_SOLDIER, lv, n)
                                if action ~= TroopAction.LostTemple and action ~= TroopAction.SiegeNpc then
                                    --周限时活动
                                    weekly_activity.process_weekly_activity(p, WEEKLY_ACTIVITY_ACTION.KILL_ARM, lv, n)
                                    --运营活动
                                    operate_activity.process_operate_activity(p, OPERATE_ACTIVITY_ACTION.KILL_SOLDIER, lv, n)
                                end
                            end
                        end
                    end
                end
            end
            --dumpTab( arm, "calc_kill_for_arm" )
        end
    end
    --dumpTab( result, "fight_result" )
end

