--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_mc_stage = {

	[MONSTER_STAGE_1] = { ID = MONSTER_STAGE_1, Start = {hour = 12, min = 0}, End = {hour = 16, min = 0}, Spantime = 60, NextStage = 2,},
	[MONSTER_STAGE_2] = { ID = MONSTER_STAGE_2, Start = 0, End = 0, Spantime = 60, NextStage = 3,},
	[MONSTER_STAGE_3] = { ID = MONSTER_STAGE_3, Start = 0, End = 0, Spantime = 60, NextStage = 4,},
	[MONSTER_STAGE_4] = { ID = MONSTER_STAGE_4, Start = 0, End = 0, Spantime = 180, NextStage = 5,},
	[MONSTER_STAGE_5] = { ID = MONSTER_STAGE_5, Start = 0, End = 0, Spantime = 180, NextStage = 6,},
	[MONSTER_STAGE_6] = { ID = MONSTER_STAGE_6, Start = 0, End = 0, Spantime = 90, NextStage = 7,},
	[MONSTER_STAGE_7] = { ID = MONSTER_STAGE_7, Start = 0, End = 0, Spantime = 90, NextStage = 8,},
	[MONSTER_STAGE_8] = { ID = MONSTER_STAGE_8, Start = 0, End = 0, Spantime = 90, NextStage = 9,},
	[MONSTER_STAGE_9] = { ID = MONSTER_STAGE_9, Start = 0, End = 0, Spantime = 300, NextStage = 10,},
	[MONSTER_STAGE_10] = { ID = MONSTER_STAGE_10, Start = 0, End = 0, Spantime = 300, NextStage = 11,},
	[MONSTER_STAGE_11] = { ID = MONSTER_STAGE_11, Start = 0, End = 0, Spantime = 120, NextStage = 12,},
	[MONSTER_STAGE_12] = { ID = MONSTER_STAGE_12, Start = 0, End = 0, Spantime = 120, NextStage = 13,},
	[MONSTER_STAGE_13] = { ID = MONSTER_STAGE_13, Start = 0, End = 0, Spantime = 120, NextStage = 14,},
	[MONSTER_STAGE_14] = { ID = MONSTER_STAGE_14, Start = 0, End = 0, Spantime = 480, NextStage = 15,},
	[MONSTER_STAGE_15] = { ID = MONSTER_STAGE_15, Start = 0, End = 0, Spantime = 480, NextStage = 16,},
	[MONSTER_STAGE_16] = { ID = MONSTER_STAGE_16, Start = 0, End = 0, Spantime = 240, NextStage = 17,},
	[MONSTER_STAGE_17] = { ID = MONSTER_STAGE_17, Start = 0, End = 0, Spantime = 240, NextStage = 18,},
	[MONSTER_STAGE_18] = { ID = MONSTER_STAGE_18, Start = 0, End = 0, Spantime = 240, NextStage = 19,},
	[MONSTER_STAGE_19] = { ID = MONSTER_STAGE_19, Start = 0, End = 0, Spantime = 600, NextStage = 20,},
	[MONSTER_STAGE_20] = { ID = MONSTER_STAGE_20, Start = 0, End = 0, Spantime = 0, NextStage = 20,},
}
