--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_tw_stage = {

	[NPC_STAGE_1] = { ID = NPC_STAGE_1, Start = {hour = 14, min = 00}, End = {hour = 15, min = 00}, Spantime = 0, NextStage = 3, Reward = nil,},
	[NPC_STAGE_2] = { ID = NPC_STAGE_2, Start = 0, End = 0, Spantime = {10, 1, 1, 10}, NextStage = 4, Reward = nil,},
	[NPC_STAGE_3] = { ID = NPC_STAGE_3, Start = 0, End = 0, Spantime = {120, 90, 60, 30}, NextStage = 2, Reward = nil,},
	[TW_PEACE_AWARD] = { ID = TW_PEACE_AWARD, Start = nil, End = nil, Spantime = nil, NextStage = nil, Reward = {"mutual_award",{{"item",1001001,19087,2500},{"item",1002001,19087,2500},{"item",1003001,19087,2500},{"item",1004008,19087,2500}}},},
	[TW_RANDOM_AWARD] = { ID = TW_RANDOM_AWARD, Start = nil, End = nil, Spantime = nil, NextStage = nil, Reward = {"mutual_award",{{"item",1001001,19087,2500},{"item",1002001,19087,2500},{"item",1003001,19087,2500},{"item",1004008,19087,2500}}},},
}
