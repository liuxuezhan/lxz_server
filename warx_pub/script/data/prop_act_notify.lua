--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_act_notify = {

	[FORTRESS_BUFF] = { ID = FORTRESS_BUFF, Notify = nil, Chat1 = nil, Chat2 = 60059, SendMail = nil,},
	[ANCIENT_FORTRESS_OCCUPY] = { ID = ANCIENT_FORTRESS_OCCUPY, Notify = 60028, Chat1 = 60028, Chat2 = 60060, SendMail = nil,},
	[GUARD_TOWER_PARALYSIS_1] = { ID = GUARD_TOWER_PARALYSIS_1, Notify = 60029, Chat1 = 60029, Chat2 = 60061, SendMail = nil,},
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
	[KW_START] = { ID = KW_START, Notify = 60083, Chat1 = 60085, Chat2 = nil, SendMail = nil,},
	[KW_END] = { ID = KW_END, Notify = 60084, Chat1 = 60086, Chat2 = nil, SendMail = nil,},
	[KW_PREPARE] = { ID = KW_PREPARE, Notify = 60112, Chat1 = 60113, Chat2 = nil, SendMail = nil,},
	[KW_FORTRESS_OPEN] = { ID = KW_FORTRESS_OPEN, Notify = 60239, Chat1 = 60241, Chat2 = nil, SendMail = nil,},
	[KW_FORTRESS_CLOSE] = { ID = KW_FORTRESS_CLOSE, Notify = 60240, Chat1 = 60242, Chat2 = nil, SendMail = nil,},
	[KW_CROWN] = { ID = KW_CROWN, Notify = 60243, Chat1 = 60244, Chat2 = nil, SendMail = nil,},
	[MC_ROLLCALL] = { ID = MC_ROLLCALL, Notify = nil, Chat1 = nil, Chat2 = 60234, SendMail = nil,},
	[MC_SUPPORT] = { ID = MC_SUPPORT, Notify = nil, Chat1 = nil, Chat2 = 60235, SendMail = nil,},
	[MC_LOSE] = { ID = MC_LOSE, Notify = 60237, Chat1 = 60237, Chat2 = 60236, SendMail = nil,},
	[KW_SPECIAL_PREPARE] = { ID = KW_SPECIAL_PREPARE, Notify = 60238, Chat1 = 60238, Chat2 = nil, SendMail = nil,},
	[TW_FIGHT] = { ID = TW_FIGHT, Notify = 60252, Chat1 = 60253, Chat2 = 60254, SendMail = nil,},
	[KING_ONLINE_NOUNION] = { ID = KING_ONLINE_NOUNION, Notify = 60384, Chat1 = 60385, Chat2 = nil, SendMail = nil,},
	[TW_PREPARE_SPECIAL] = { ID = TW_PREPARE_SPECIAL, Notify = 60458, Chat1 = 60459, Chat2 = nil, SendMail = nil,},
	[TW_FIGHT_SPECIAL] = { ID = TW_FIGHT_SPECIAL, Notify = 60460, Chat1 = 60461, Chat2 = nil, SendMail = nil,},
	[OFFICIAL_APPOINTMENT_NO_UNION] = { ID = OFFICIAL_APPOINTMENT_NO_UNION, Notify = 60492, Chat1 = 60492, Chat2 = nil, SendMail = nil,},
	[ISSUE_DECREE] = { ID = ISSUE_DECREE, Notify = 60491, Chat1 = 60491, Chat2 = nil, SendMail = nil,},
	[TW_START] = { ID = TW_START, Notify = 60517, Chat1 = 60516, Chat2 = nil, SendMail = nil,},
	[TW_END] = { ID = TW_END, Notify = 60519, Chat1 = 60518, Chat2 = nil, SendMail = nil,},
	[MC_SUCCESS] = { ID = MC_SUCCESS, Notify = nil, Chat1 = nil, Chat2 = 60520, SendMail = nil,},
	[LT_OCCUPY] = { ID = LT_OCCUPY, Notify = 60522, Chat1 = 60521, Chat2 = nil, SendMail = nil,},
	[LT_GATHER] = { ID = LT_GATHER, Notify = 60524, Chat1 = 60523, Chat2 = nil, SendMail = nil,},
	[SUPER_BOSS_REFRESH] = { ID = SUPER_BOSS_REFRESH, Notify = 60526, Chat1 = 60525, Chat2 = 60527, SendMail = nil,},
	[BOSS_FIRST_BLOOD] = { ID = BOSS_FIRST_BLOOD, Notify = 60579, Chat1 = 60580, Chat2 = nil, SendMail = nil,},
	[SUPER_BOSS_KILL] = { ID = SUPER_BOSS_KILL, Notify = 60582, Chat1 = 60583, Chat2 = nil, SendMail = nil,},
	[MC_DIFFICULTY_SETTING] = { ID = MC_DIFFICULTY_SETTING, Notify = nil, Chat1 = nil, Chat2 = 60601, SendMail = nil,},
	[NEW_LEADER] = { ID = NEW_LEADER, Notify = nil, Chat1 = nil, Chat2 = 60585, SendMail = nil,},
}
