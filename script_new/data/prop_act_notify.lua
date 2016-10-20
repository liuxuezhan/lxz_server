--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_act_notify = {

	[FORTRESS_BUFF] = { ID = FORTRESS_BUFF, Notify = nil, Chat1 = nil, Chat2 = 60059, SendMail = nil,},
	[ANCIENT_FORTRESS_OCCUPY] = { ID = ANCIENT_FORTRESS_OCCUPY, Notify = 60028, Chat1 = nil, Chat2 = 60060, SendMail = nil,},
	[GUARD_TOWER_PARALYSIS_1] = { ID = GUARD_TOWER_PARALYSIS_1, Notify = 60029, Chat1 = nil, Chat2 = 60061, SendMail = nil,},
	[GUARD_TOWER_PARALYSIS_2] = { ID = GUARD_TOWER_PARALYSIS_2, Notify = nil, Chat1 = nil, Chat2 = 60062, SendMail = nil,},
	[GUARD_TOWER_RECOVERY_1] = { ID = GUARD_TOWER_RECOVERY_1, Notify = 60030, Chat1 = nil, Chat2 = nil, SendMail = nil,},
	[KW_OCCUPY_TIME] = { ID = KW_OCCUPY_TIME, Notify = 60031, Chat1 = 60055, Chat2 = nil, SendMail = nil,},
	[KING_ONLINE] = { ID = KING_ONLINE, Notify = 60033, Chat1 = 60057, Chat2 = nil, SendMail = nil,},
	[OFFICIAL_APPOINTMENT] = { ID = OFFICIAL_APPOINTMENT, Notify = 60034, Chat1 = 60058, Chat2 = nil, SendMail = nil,},
	[MC_TIMESET] = { ID = MC_TIMESET, Notify = nil, Chat1 = nil, Chat2 = 60063, SendMail = nil,},
	[MC_OPEN] = { ID = MC_OPEN, Notify = nil, Chat1 = nil, Chat2 = 60064, SendMail = nil,},
	[MC_COUNTERATTACK] = { ID = MC_COUNTERATTACK, Notify = nil, Chat1 = nil, Chat2 = 60065, SendMail = nil,},
	[MC_PREPARE] = { ID = MC_PREPARE, Notify = nil, Chat1 = nil, Chat2 = 60066, SendMail = nil,},
	[TW_PREPARE] = { ID = TW_PREPARE, Notify = nil, Chat1 = nil, Chat2 = 60067, SendMail = nil,},
	[LT_OPEN] = { ID = LT_OPEN, Notify = 60036, Chat1 = 60068, Chat2 = nil, SendMail = nil,},
	[BIG_LT_REFRESH] = { ID = BIG_LT_REFRESH, Notify = 60037, Chat1 = 60069, Chat2 = nil, SendMail = nil,},
	[MIDDLE_LT_REFRESH] = { ID = MIDDLE_LT_REFRESH, Notify = 60038, Chat1 = 60070, Chat2 = nil, SendMail = nil,},
	[LT_START] = { ID = LT_START, Notify = 60078, Chat1 = 60080, Chat2 = nil, SendMail = nil,},
	[LT_END] = { ID = LT_END, Notify = 60079, Chat1 = 60081, Chat2 = nil, SendMail = nil,},
}
