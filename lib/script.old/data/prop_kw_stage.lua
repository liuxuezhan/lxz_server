--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_kw_stage = {

	[KW_STAGE_1] = { ID = KW_STAGE_1, Start = {hour = 12, min = 0}, End = {hour = 16, min = 0}, Spantime = nil, NextStage = 2,},
	[KW_STAGE_2] = { ID = KW_STAGE_2, Start = 0, End = 0, Spantime = 0, NextStage = 4,},
	[KW_STAGE_3] = { ID = KW_STAGE_3, Start = 0, End = 0, Spantime = 5, NextStage = 5,},
	[KW_STAGE_4] = { ID = KW_STAGE_4, Start = 0, End = 0, Spantime = 10, NextStage = 5,},
	[KW_STAGE_5] = { ID = KW_STAGE_5, Start = 0, End = 0, Spantime = 5, NextStage = 3,},
}
