--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_lt_stage = {

	[LOST_STAGE_1] = { ID = LOST_STAGE_1, Start = nil, End = nil, Spantime = 259199, NextStage = 2,},
	[LOST_STAGE_2] = { ID = LOST_STAGE_2, Start = nil, End = nil, Spantime = 86400, NextStage = 3,},
	[LOST_STAGE_3] = { ID = LOST_STAGE_3, Start = 0, End = 0, Spantime = 259199, NextStage = 2,},
}
