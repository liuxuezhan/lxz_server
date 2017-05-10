--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_union_award = {

	[LEG_AWARD_50101] = { ID = LEG_AWARD_50101, Class = 5, Mode = 1, lv = 1, Item = {"mutex_award",{{"item",2013198,1,10000}}},},
	[LEG_AWARD_50102] = { ID = LEG_AWARD_50102, Class = 5, Mode = 1, lv = 2, Item = {"mutex_award",{{"item",2013203,1,10000}}},},
	[LEG_AWARD_50103] = { ID = LEG_AWARD_50103, Class = 5, Mode = 1, lv = 3, Item = {"mutex_award",{{"item",2013208,1,10000}}},},
	[LEG_AWARD_50104] = { ID = LEG_AWARD_50104, Class = 5, Mode = 1, lv = 4, Item = {"mutex_award",{{"item",2013213,1,10000}}},},
	[LEG_AWARD_50105] = { ID = LEG_AWARD_50105, Class = 5, Mode = 1, lv = 5, Item = {"mutex_award",{{"item",2013218,1,10000}}},},
	[LEG_AWARD_50106] = { ID = LEG_AWARD_50106, Class = 5, Mode = 1, lv = 6, Item = {"mutex_award",{{"item",2013223,1,10000}}},},
	[LEG_AWARD_50107] = { ID = LEG_AWARD_50107, Class = 5, Mode = 1, lv = 7, Item = {"mutex_award",{{"item",2013228,1,10000}}},},
	[LEG_AWARD_50108] = { ID = LEG_AWARD_50108, Class = 5, Mode = 1, lv = 8, Item = {"mutex_award",{{"item",2013233,1,10000}}},},
	[LEG_AWARD_50109] = { ID = LEG_AWARD_50109, Class = 5, Mode = 1, lv = 9, Item = {"mutex_award",{{"item",2013238,1,10000}}},},
	[LEG_AWARD_50110] = { ID = LEG_AWARD_50110, Class = 5, Mode = 1, lv = 10, Item = {"mutex_award",{{"item",2013243,1,10000}}},},
	[LEG_AWARD_50111] = { ID = LEG_AWARD_50111, Class = 5, Mode = 1, lv = 11, Item = {"mutex_award",{{"item",2013248,1,10000}}},},
	[LEG_AWARD_50201] = { ID = LEG_AWARD_50201, Class = 5, Mode = 2, lv = 1, Item = {"mutex_award",{{"item",2013010,1,10000}}},},
	[LEG_AWARD_50202] = { ID = LEG_AWARD_50202, Class = 5, Mode = 2, lv = 2, Item = {"mutex_award",{{"item",2013015,1,10000}}},},
	[LEG_AWARD_50203] = { ID = LEG_AWARD_50203, Class = 5, Mode = 2, lv = 3, Item = {"mutex_award",{{"item",2013020,1,10000}}},},
	[LEG_AWARD_50204] = { ID = LEG_AWARD_50204, Class = 5, Mode = 2, lv = 4, Item = {"mutex_award",{{"item",2013025,1,10000}}},},
	[LEG_AWARD_50205] = { ID = LEG_AWARD_50205, Class = 5, Mode = 2, lv = 5, Item = {"mutex_award",{{"item",2013030,1,10000}}},},
	[LEG_AWARD_50206] = { ID = LEG_AWARD_50206, Class = 5, Mode = 2, lv = 6, Item = {"mutex_award",{{"item",2013035,1,10000}}},},
	[LEG_AWARD_50207] = { ID = LEG_AWARD_50207, Class = 5, Mode = 2, lv = 7, Item = {"mutex_award",{{"item",2013040,1,10000}}},},
	[LEG_AWARD_50208] = { ID = LEG_AWARD_50208, Class = 5, Mode = 2, lv = 8, Item = {"mutex_award",{{"item",2013045,1,10000}}},},
	[LEG_AWARD_50209] = { ID = LEG_AWARD_50209, Class = 5, Mode = 2, lv = 9, Item = {"mutex_award",{{"item",2013050,1,10000}}},},
	[LEG_AWARD_50210] = { ID = LEG_AWARD_50210, Class = 5, Mode = 2, lv = 10, Item = {"mutex_award",{{"item",2013055,1,10000}}},},
	[LEG_AWARD_50211] = { ID = LEG_AWARD_50211, Class = 5, Mode = 2, lv = 11, Item = {"mutex_award",{{"item",2013060,1,10000}}},},
	[LEG_AWARD_50301] = { ID = LEG_AWARD_50301, Class = 5, Mode = 3, lv = 1, Item = {"mutex_award",{{"item",2013110,1,10000}}},},
	[LEG_AWARD_50302] = { ID = LEG_AWARD_50302, Class = 5, Mode = 3, lv = 2, Item = {"mutex_award",{{"item",2013115,1,10000}}},},
	[LEG_AWARD_50303] = { ID = LEG_AWARD_50303, Class = 5, Mode = 3, lv = 3, Item = {"mutex_award",{{"item",2013120,1,10000}}},},
	[LEG_AWARD_50304] = { ID = LEG_AWARD_50304, Class = 5, Mode = 3, lv = 4, Item = {"mutex_award",{{"item",2013125,1,10000}}},},
	[LEG_AWARD_50305] = { ID = LEG_AWARD_50305, Class = 5, Mode = 3, lv = 5, Item = {"mutex_award",{{"item",2013130,1,10000}}},},
	[LEG_AWARD_50306] = { ID = LEG_AWARD_50306, Class = 5, Mode = 3, lv = 6, Item = {"mutex_award",{{"item",2013135,1,10000}}},},
	[LEG_AWARD_50307] = { ID = LEG_AWARD_50307, Class = 5, Mode = 3, lv = 7, Item = {"mutex_award",{{"item",2013140,1,10000}}},},
	[LEG_AWARD_50308] = { ID = LEG_AWARD_50308, Class = 5, Mode = 3, lv = 8, Item = {"mutex_award",{{"item",2013145,1,10000}}},},
	[LEG_AWARD_50309] = { ID = LEG_AWARD_50309, Class = 5, Mode = 3, lv = 9, Item = {"mutex_award",{{"item",2013150,1,10000}}},},
	[LEG_AWARD_50310] = { ID = LEG_AWARD_50310, Class = 5, Mode = 3, lv = 10, Item = {"mutex_award",{{"item",2013155,1,10000}}},},
	[LEG_AWARD_50311] = { ID = LEG_AWARD_50311, Class = 5, Mode = 3, lv = 11, Item = {"mutex_award",{{"item",2013160,1,10000}}},},
	[LEG_AWARD_50100] = { ID = LEG_AWARD_50100, Class = 5, Mode = 1, lv = 0, Item = {"mutex_award",{{"item",2013193,1,10000}}},},
	[LEG_AWARD_50200] = { ID = LEG_AWARD_50200, Class = 5, Mode = 2, lv = 0, Item = {"mutex_award",{{"item",2013005,1,10000}}},},
	[LEG_AWARD_50300] = { ID = LEG_AWARD_50300, Class = 5, Mode = 3, lv = 0, Item = {"mutex_award",{{"item",2013105,1,10000}}},},
}
