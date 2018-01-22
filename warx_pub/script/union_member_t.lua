--玩家军团信息模块
module(..., package.seeall)
function load(pid)
    local db = dbmng:getOne()
    local info 
    if pid then
        info = db.union_member:find({_id=pid})
    else
        info = db.union_member:find({})
    end
    while info:hasNext() do
        local data = info:next()
        local p = getPlayer(data._id)
        if p then
            p._union = data
            local union = unionmng.get_union(p:get_uid())
            if union then
                if union._members then
                    union._members[p.pid] = p
                else
                    local _members = {}
                    _members[p.pid] = p
                    union._members = _members
                end
            end

            local buildlv = {}
            for k,v in pairs (data.buildlv or {}) do
                if k~="_n_"  then
                    buildlv[ v.mode ] = v
                end
            end
            data.buildlv = buildlv
        else
            INFO("load_union_member, not found player", data._id)
        end
    end
end

function create(ply, uid, rank)
    local data = {
        _id = ply.pid,
        uid = uid,
        title = "",
        rank = 0,                   --联盟阶级
        credit = 0,
        history = {},               --历史加入的联盟
        donate = 0,                 --可用捐献
        donate_data = {0,0,0,0,0,0},    --捐献排行贡献
        techexp_data = {0,0,0,0,0,0},   --捐献排行科技点
        date = {tm=0, val={}},   --跨天清除数据
        mark = "",                   --联盟标记
        tmJoin = 0,                 --加入联盟的时间
        tmLeave = 0,                --离开联盟的时间
        donate_flag = 0,            --可否捐献
        tmDonate = 0,               --捐献cd
        buildlv = {},
        god_log = {lv=0,tm=0},       --战神膜拜记录
        tm_mission = 0,             --领取军团任务时间tag
        cur_item = {},               --已领军团任务奖励
        --join_tm = 0, --加入军团的次数

        restore_sum = {0,0,0,0},
        restore_day = {0,0},
        word = {},
    }
    gPendingSave.union_member[ply.pid] = data
    ply._union = data
end


function get_donate_flag(ply)
    if (ply._union.tmDonate or 0) <= gTime and ply._union.donate_flag ~= 0 then
        ply._union.donate_flag = 0
        gPendingSave.union_member[ply.pid] = ply._union
    end
    return ply._union.donate_flag
end


function add_donate(ply, num,r)
    if num < 0 then ERROR("%d add_donate num err",ply.pid) return end
    ply._union.donate = ply._union.donate + num
    gPendingSave.union_member[ply.pid].donate = ply._union.donate

end

function add_donate_rank(ply, exp,num,r)
    if num < 0 then ERROR("%d add_donate_rank num err",ply.pid) return end

	if r== 1 then
		for i = DONATE_RANKING_TYPE.DAY, DONATE_RANKING_TYPE.UNION do
			ply._union.techexp_data[i] = ply._union.techexp_data[i] + exp
			ply._union.donate_data[i] = ply._union.donate_data[i] + num
		end
	elseif r== 2 then
		for i = DONATE_RANKING_TYPE.DAY_B, DONATE_RANKING_TYPE.UNION_B do
			ply._union.techexp_data[i] = ply._union.techexp_data[i] + exp
			ply._union.donate_data[i] = ply._union.donate_data[i] + 1
		end
	end
    gPendingSave.union_member[ply.pid].techexp_data = ply._union.techexp_data
    gPendingSave.union_member[ply.pid].donate_data = ply._union.donate_data
    local union = unionmng.get_union(ply:get_uid())
    if union then union.donate_rank = {} end
end

function clear_donate_data(ply, what)
    ply._union.donate_data[what] = 0
    ply._union.techexp_data[what] = 0

    local chg = gPendingSave.union_member[ ply.pid ]
    chg.donate_data = ply._union.donate_data
    chg.techexp_data = ply._union.techexp_data
end

function leave_union(ply)
    add_history(ply,{
        uid=ply:get_uid(),
        tmJoin = ply._union.tmJoin,
        tmLeave = gTime,
        rank = ply._union.rank,
    })
    local data = ply._union
    data.uid = 0
    data.tmLeave = gTime
    data.mark = ""
    data.title = ""
    data.rank = 0
    data.tmJoin = 0
    data.donate_flag = 1
    data.donate_data = {0,0,0,0,0,0}
    data.techexp_data = {0,0,0,0,0,0}
    data.restore_sum = {0,0,0,0}
    data.restore_day = {0,0}
    data.word = {}

    local chg = gPendingSave.union_member[ ply.pid ]
    chg.uid = 0
    chg.tmLeave = gTime
    chg.mark = ""
    chg.title = ""
    chg.rank = 0
    chg.tmJoin = 0
    chg.donate_flag = 1
    chg.donate_data = {0,0,0,0,0,0}
    chg.techexp_data = {0,0,0,0,0,0}
    chg.restore_sum = {0,0,0,0}
    chg.restore_day = {0,0}
    chg.word = {}

end


function join_union(ply, union)
    local data = ply._union
    data.uid = union.uid
    data.tmJoin = gTime
    --data.join_tm = ( data.join_tm or 0 ) + 1
    data.rank = resmng.UNION_RANK_1
    data.restore_sum = {0,0,0,0}
    data.restore_day = {0,0}

    local chg = gPendingSave.union_member[ ply.pid ]
    chg.uid = union.uid
    chg.tmJoin = gTime
    --chg.join_tm = ( data.join_tm or 0 ) + 1
    chg.rank = resmng.UNION_RANK_1
    chg.restore_sum = {0,0,0,0}
    chg.restore_day = {0,0}
    INFO( "[UNION], join, pid=%d, uid=%d", ply.pid, union.uid )
end




function add_history(ply, data)
    table.insert(ply._union.history, 1, data)
    local out = #ply._union.history - 20
    for i = 1, out, 1 do
        table.remove(ply._union.history)
    end
    gPendingSave.union_member[ply.pid] = ply._union
end


