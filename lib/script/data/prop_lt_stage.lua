--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_lt_stage = {

	[LOST_STAGE_1] = { ID = LOST_STAGE_1, Start = {hour = 12, min = 0}, End = {hour = 16, min = 0}, Spantime = nil, NextStage = 2,},
	[LOST_STAGE_2] = { ID = LOST_STAGE_2, Start = 0, End = 0, Spantime = 3 * 24 * 60, NextStage = 4,},
}
