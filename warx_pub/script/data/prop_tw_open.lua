--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_tw_open = {

	[TW_STAGE_1] = { ID = TW_STAGE_1, Wait = nil, CountDown = 43200, Awardtm = 244800, Span = 43200, NextStage = 2,},
	[TW_STAGE_2] = { ID = TW_STAGE_2, Wait = 86400, CountDown = 43200, Awardtm = 345600, Span = 144000, NextStage = 2,},
	[TW_STAGE_3] = { ID = TW_STAGE_3, Wait = nil, CountDown = 28800, Awardtm = nil, Span = 28800, NextStage = 1,},
}
