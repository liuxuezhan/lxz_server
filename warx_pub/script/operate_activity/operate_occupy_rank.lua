module("operate_activity", package.seeall)

--领主排行榜
OccupyRankActivity = DeclareClass("OccupyRankActivity", CActivityBase)

--活动开始
function OccupyRankActivity:init_activity()
	self.last_refresh_time = gTime
	local prop_tab = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_tab == nil or prop_tab.ActionRange == nil then
		return
	end
	self.city_base_score = {}
	self.member_score = 0
	for i = prop_tab.ActionRange[1], prop_tab.ActionRange[2], 1 do
		local prop_tab = resmng.get_conf("prop_operate_action", i)
		local type, parm = unpack(prop_tab.Action)
		if type == "occupy_city" then
			self.city_base_score[parm] = prop_tab.Score
		else
			self.member_score = prop_tab.Score / parm
		end
	end
	
end

--活动结束
function OccupyRankActivity:end_activity()
	self:refresh_rank()
	--发奖
	local prop_tab = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_tab == nil or prop_tab.Rank == nil or prop_tab.RankRange == nil then
		return
	end
	local s_id = prop_tab.RankRange[1]
	local e_id = prop_tab.RankRange[2]

	for i = s_id, e_id, 1 do
		local prop_award = resmng.get_conf("prop_operate_award_rank", i)
		if prop_award ~= nil then
			local uids = rank_mng.get_range(prop_tab.Rank, prop_award.RankRange[1], prop_award.RankRange[2])
			local temp_rank = prop_award.RankRange[1]
			for k, uid in pairs(uids or {}) do
				local union = unionmng.get_union(uid)
				if union ~= nil then
					local members = union:get_all_members()
					for _, ply in pairs(members or {}) do
						ply:send_system_notice(prop_award.Mail, {}, {temp_rank}, prop_award.Bonus[2])
					end
				end
				temp_rank = temp_rank + 1
			end
		end
	end
end

function OccupyRankActivity:loop()
	if gTime < self.last_refresh_time + 3600 then
		return
	end
	self.last_refresh_time = gTime
	if self.is_start == 1 then
		self:refresh_rank()
	end
end

function OccupyRankActivity:refresh_rank()
	local prop_tab = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_tab == nil or prop_tab.Rank == nil then
		return
	end

	local unions = unionmng.get_all()
	for _, union in pairs(unions or {}) do
		local total_score = 0
		local city_score = 0
		local member_score = 0

		if union:is_new() == false then
			--城市
			for k, v in pairs(union.npc_citys or {}) do
				local city = get_ety(v)
				if city ~= nil then
					local prop_build = resmng.get_conf("prop_world_unit", city.propid)
					if prop_build ~= nil then
						city_score = city_score + self.city_base_score[prop_build.Lv]
					end
				end
			end

			--成员
			local members = union:get_all_members()
			for _, ply in pairs(members or {}) do
				member_score = member_score + ply:get_pow() * self.member_score
			end
			member_score = math.floor(member_score)
			total_score = city_score + member_score
			rank_mng.add_data(prop_tab.Rank, union.uid, {total_score})
		end
	end
end

--继承函数
function OccupyRankActivity:handout_rank_award()
end


