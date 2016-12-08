--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_mail = {

	[MAIL_10001] = { ID = MAIL_10001, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10001, Content = LG_MAIL_CONTENT_10001, AddBonus = nil,},
	[MAIL_10002] = { ID = MAIL_10002, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10002, Content = LG_MAIL_CONTENT_10002, AddBonus = {"mutex_award",{{"res",8,5000,10000}}},},
	[MAIL_20001] = { ID = MAIL_20001, Class = 2, Name = LG_NIL, Title = LG_MAIL_TITLE_20001, Content = LG_MAIL_CONTENT_20001, AddBonus = nil,},
	[MAIL_30001] = { ID = MAIL_30001, Class = 3, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_30001, Content = LG_MAIL_CONTENT_30001, AddBonus = nil,},
	[MAIL_10003] = { ID = MAIL_10003, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10003, Content = LG_MAIL_CONTENT_10003, AddBonus = nil,},
	[MAIL_10004] = { ID = MAIL_10004, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10003, Content = LG_MAIL_CONTENT_10004, AddBonus = nil,},
	[MAIL_10005] = { ID = MAIL_10005, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10004, Content = LG_MAIL_CONTENT_10005, AddBonus = nil,},
	[MAIL_10006] = { ID = MAIL_10006, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10005, Content = LG_MAIL_CONTENT_10006, AddBonus = nil,},
	[MAIL_10007] = { ID = MAIL_10007, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10006, Content = LG_MAIL_CONTENT_10007, AddBonus = nil,},
	[MAIL_10008] = { ID = MAIL_10008, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10007, Content = LG_MAIL_CONTENT_10008, AddBonus = nil,},
	[MAIL_10009] = { ID = MAIL_10009, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10008, Content = LG_MAIL_CONTENT_10009, AddBonus = nil,},
	[MAIL_10010] = { ID = MAIL_10010, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10009, Content = LG_MAIL_CONTENT_10010, AddBonus = nil,},
	[MAIL_10011] = { ID = MAIL_10011, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10010, Content = LG_MAIL_CONTENT_10011, AddBonus = nil,},
	[MAIL_10012] = { ID = MAIL_10012, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10011, Content = LG_MAIL_CONTENT_10012, AddBonus = nil,},
	[MAIL_10013] = { ID = MAIL_10013, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10012, Content = LG_MAIL_CONTENT_10013, AddBonus = nil,},
	[MAIL_10014] = { ID = MAIL_10014, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10013, Content = LG_MAIL_CONTENT_10014, AddBonus = nil,},
	[MAIL_10015] = { ID = MAIL_10015, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10014, Content = LG_MAIL_CONTENT_10015, AddBonus = nil,},
	[MAIL_10016] = { ID = MAIL_10016, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10015, Content = LG_MAIL_CONTENT_10016, AddBonus = nil,},
	[MAIL_10017] = { ID = MAIL_10017, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10016, Content = LG_MAIL_CONTENT_10017, AddBonus = nil,},
	[MAIL_10018] = { ID = MAIL_10018, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10017, Content = LG_MAIL_CONTENT_10018, AddBonus = nil,},
	[MAIL_10019] = { ID = MAIL_10019, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10018, Content = LG_MAIL_CONTENT_10019, AddBonus = nil,},
	[MAIL_10020] = { ID = MAIL_10020, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10019, Content = LG_MAIL_CONTENT_10020, AddBonus = nil,},
	[MAIL_10021] = { ID = MAIL_10021, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10020, Content = LG_MAIL_CONTENT_10021, AddBonus = nil,},
	[MAIL_10022] = { ID = MAIL_10022, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10021, Content = LG_MAIL_CONTENT_10022, AddBonus = nil,},
	[MAIL_10023] = { ID = MAIL_10023, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10022, Content = LG_MAIL_CONTENT_10023, AddBonus = nil,},
	[MAIL_10024] = { ID = MAIL_10024, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10024, Content = LG_MAIL_CONTENT_10024, AddBonus = nil,},
	[MAIL_10025] = { ID = MAIL_10025, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10025, Content = LG_MAIL_CONTENT_10025, AddBonus = nil,},
	[MAIL_10026] = { ID = MAIL_10026, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10026, Content = LG_MAIL_CONTENT_10026, AddBonus = nil,},
	[MAIL_10027] = { ID = MAIL_10027, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10027, Content = LG_MAIL_CONTENT_10027, AddBonus = nil,},
	[MAIL_10028] = { ID = MAIL_10028, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10028, Content = LG_MAIL_CONTENT_10028, AddBonus = nil,},
	[MAIL_10029] = { ID = MAIL_10029, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10029, Content = LG_MAIL_CONTENT_10029, AddBonus = nil,},
	[MAIL_10030] = { ID = MAIL_10030, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10030, Content = LG_MAIL_CONTENT_10030, AddBonus = nil,},
	[MAIL_10031] = { ID = MAIL_10031, Class = 1, Name = LG_MAIL_NAME_10001, Title = LG_MAIL_TITLE_10031, Content = LG_MAIL_CONTENT_10031, AddBonus = nil,},
}
