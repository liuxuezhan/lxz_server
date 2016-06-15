--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_tw_stage = {

	[NPC_STAGE_1] = { ID = NPC_STAGE_1, Start = {hour = 14, min = 00}, End = {hour = 15, min = 00}, Spantime = 0, NextStage = 3, Reward = nil,},
	[NPC_STAGE_2] = { ID = NPC_STAGE_2, Start = 0, End = 0, Spantime = {1, 1, 1, 1}, NextStage = 4, Reward = nil,},
	[NPC_STAGE_3] = { ID = NPC_STAGE_3, Start = 0, End = 0, Spantime = {30, 60, 90, 120}, NextStage = 2, Reward = nil,},
	[TW_PEACE_AWARD] = { ID = TW_PEACE_AWARD, Start = nil, End = nil, Spantime = nil, NextStage = nil, Reward = nil,},
	[TW_RANDOM_AWARD] = { ID = TW_RANDOM_AWARD, Start = nil, End = nil, Spantime = nil, NextStage = nil, Reward = nil,},
}
