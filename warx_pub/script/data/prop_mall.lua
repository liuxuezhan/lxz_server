--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_mall = {

	[MALL_ITEM_1] = { ID = MALL_ITEM_1, Class = 1, Item = {{"item",1002003,1,10000}}, OldPrice = 40, NewPrice = 40, CheckUse = nil,},
	[MALL_ITEM_2] = { ID = MALL_ITEM_2, Class = 1, Item = {{"item",1002004,1,10000}}, OldPrice = 160, NewPrice = 160, CheckUse = nil,},
	[MALL_ITEM_3] = { ID = MALL_ITEM_3, Class = 1, Item = {{"item",1002005,1,10000}}, OldPrice = 400, NewPrice = 400, CheckUse = nil,},
	[MALL_ITEM_4] = { ID = MALL_ITEM_4, Class = 1, Item = {{"item",1002006,1,10000}}, OldPrice = 1200, NewPrice = 1200, CheckUse = nil,},
	[MALL_ITEM_5] = { ID = MALL_ITEM_5, Class = 1, Item = {{"item",1002007,1,10000}}, OldPrice = 3300, NewPrice = 3300, CheckUse = nil,},
	[MALL_ITEM_6] = { ID = MALL_ITEM_6, Class = 1, Item = {{"item",1002008,1,10000}}, OldPrice = 10000, NewPrice = 10000, CheckUse = nil,},
	[MALL_ITEM_7] = { ID = MALL_ITEM_7, Class = 1, Item = {{"item",1001003,1,10000}}, OldPrice = 40, NewPrice = 40, CheckUse = nil,},
	[MALL_ITEM_8] = { ID = MALL_ITEM_8, Class = 1, Item = {{"item",1001004,1,10000}}, OldPrice = 160, NewPrice = 160, CheckUse = nil,},
	[MALL_ITEM_9] = { ID = MALL_ITEM_9, Class = 1, Item = {{"item",1001005,1,10000}}, OldPrice = 400, NewPrice = 400, CheckUse = nil,},
	[MALL_ITEM_10] = { ID = MALL_ITEM_10, Class = 1, Item = {{"item",1001006,1,10000}}, OldPrice = 1200, NewPrice = 1200, CheckUse = nil,},
	[MALL_ITEM_11] = { ID = MALL_ITEM_11, Class = 1, Item = {{"item",1001007,1,10000}}, OldPrice = 3300, NewPrice = 3300, CheckUse = nil,},
	[MALL_ITEM_12] = { ID = MALL_ITEM_12, Class = 1, Item = {{"item",1001008,1,10000}}, OldPrice = 10000, NewPrice = 10000, CheckUse = nil,},
	[MALL_ITEM_13] = { ID = MALL_ITEM_13, Class = 1, Item = {{"item",1003003,1,10000}}, OldPrice = 40, NewPrice = 40, CheckUse = nil,},
	[MALL_ITEM_14] = { ID = MALL_ITEM_14, Class = 1, Item = {{"item",1003004,1,10000}}, OldPrice = 160, NewPrice = 160, CheckUse = nil,},
	[MALL_ITEM_15] = { ID = MALL_ITEM_15, Class = 1, Item = {{"item",1003005,1,10000}}, OldPrice = 400, NewPrice = 400, CheckUse = nil,},
	[MALL_ITEM_16] = { ID = MALL_ITEM_16, Class = 1, Item = {{"item",1003006,1,10000}}, OldPrice = 1200, NewPrice = 1200, CheckUse = nil,},
	[MALL_ITEM_17] = { ID = MALL_ITEM_17, Class = 1, Item = {{"item",1003007,1,10000}}, OldPrice = 3300, NewPrice = 3300, CheckUse = nil,},
	[MALL_ITEM_18] = { ID = MALL_ITEM_18, Class = 1, Item = {{"item",1003008,1,10000}}, OldPrice = 10000, NewPrice = 10000, CheckUse = nil,},
	[MALL_ITEM_19] = { ID = MALL_ITEM_19, Class = 1, Item = {{"item",1004002,1,10000}}, OldPrice = 40, NewPrice = 40, CheckUse = nil,},
	[MALL_ITEM_20] = { ID = MALL_ITEM_20, Class = 1, Item = {{"item",1004003,1,10000}}, OldPrice = 160, NewPrice = 160, CheckUse = nil,},
	[MALL_ITEM_21] = { ID = MALL_ITEM_21, Class = 1, Item = {{"item",1004004,1,10000}}, OldPrice = 400, NewPrice = 400, CheckUse = nil,},
	[MALL_ITEM_22] = { ID = MALL_ITEM_22, Class = 1, Item = {{"item",1004005,1,10000}}, OldPrice = 1200, NewPrice = 1200, CheckUse = nil,},
	[MALL_ITEM_23] = { ID = MALL_ITEM_23, Class = 1, Item = {{"item",1004006,1,10000}}, OldPrice = 3300, NewPrice = 3300, CheckUse = nil,},
	[MALL_ITEM_24] = { ID = MALL_ITEM_24, Class = 1, Item = {{"item",1004007,1,10000}}, OldPrice = 10000, NewPrice = 10000, CheckUse = nil,},
	[MALL_ITEM_25] = { ID = MALL_ITEM_25, Class = 1, Item = {{"item",1005002,1,10000}}, OldPrice = 20, NewPrice = 20, CheckUse = nil,},
	[MALL_ITEM_26] = { ID = MALL_ITEM_26, Class = 1, Item = {{"item",1005003,1,10000}}, OldPrice = 200, NewPrice = 200, CheckUse = nil,},
	[MALL_ITEM_27] = { ID = MALL_ITEM_27, Class = 1, Item = {{"item",1005004,1,10000}}, OldPrice = 2000, NewPrice = 2000, CheckUse = nil,},
	[MALL_ITEM_28] = { ID = MALL_ITEM_28, Class = 1, Item = {{"item",1005005,1,10000}}, OldPrice = 20000, NewPrice = 20000, CheckUse = nil,},
	[MALL_ITEM_29] = { ID = MALL_ITEM_29, Class = 1, Item = {{"item",8005001,1,10000}}, OldPrice = 250, NewPrice = 250, CheckUse = nil,},
	[MALL_ITEM_30] = { ID = MALL_ITEM_30, Class = 1, Item = {{"item",8005002,1,10000}}, OldPrice = 600, NewPrice = 600, CheckUse = nil,},
	[MALL_ITEM_31] = { ID = MALL_ITEM_31, Class = 1, Item = {{"item",8007001,1,10000}}, OldPrice = 500, NewPrice = 500, CheckUse = nil,},
	[MALL_ITEM_32] = { ID = MALL_ITEM_32, Class = 1, Item = {{"item",8007002,1,10000}}, OldPrice = 2000, NewPrice = 2000, CheckUse = nil,},
	[MALL_ITEM_33] = { ID = MALL_ITEM_33, Class = 1, Item = {{"item",8007003,1,10000}}, OldPrice = 2000, NewPrice = 2000, CheckUse = nil,},
	[MALL_ITEM_34] = { ID = MALL_ITEM_34, Class = 1, Item = {{"item",8007004,1,10000}}, OldPrice = 8000, NewPrice = 8000, CheckUse = nil,},
	[MALL_ITEM_35] = { ID = MALL_ITEM_35, Class = 2, Item = {{"item",10002001,1,10000}}, OldPrice = 500, NewPrice = 500, CheckUse = nil,},
	[MALL_ITEM_36] = { ID = MALL_ITEM_36, Class = 2, Item = {{"item",10001001,1,10000}}, OldPrice = 2000, NewPrice = 2000, CheckUse = nil,},
	[MALL_ITEM_38] = { ID = MALL_ITEM_38, Class = 2, Item = {{"item",7014001,1,10000}}, OldPrice = 600, NewPrice = 600, CheckUse = nil,},
	[MALL_ITEM_39] = { ID = MALL_ITEM_39, Class = 2, Item = {{"item",7014002,1,10000}}, OldPrice = 1000, NewPrice = 1000, CheckUse = nil,},
	[MALL_ITEM_40] = { ID = MALL_ITEM_40, Class = 2, Item = {{"item",7015001,1,10000}}, OldPrice = 50, NewPrice = 50, CheckUse = nil,},
	[MALL_ITEM_41] = { ID = MALL_ITEM_41, Class = 2, Item = {{"item",7016001,1,10000}}, OldPrice = 400, NewPrice = 400, CheckUse = nil,},
	[MALL_ITEM_42] = { ID = MALL_ITEM_42, Class = 2, Item = {{"item",7017001,1,10000}}, OldPrice = 500, NewPrice = 500, CheckUse = nil,},
	[MALL_ITEM_43] = { ID = MALL_ITEM_43, Class = 2, Item = {{"item",7018001,1,10000}}, OldPrice = 200, NewPrice = 200, CheckUse = nil,},
	[MALL_ITEM_44] = { ID = MALL_ITEM_44, Class = 2, Item = {{"item",7021001,1,10000}}, OldPrice = 1900, NewPrice = 1900, CheckUse = nil,},
	[MALL_ITEM_45] = { ID = MALL_ITEM_45, Class = 2, Item = {{"item",7022001,1,10000}}, OldPrice = 1400, NewPrice = 1400, CheckUse = nil,},
	[MALL_ITEM_46] = { ID = MALL_ITEM_46, Class = 2, Item = {{"item",8001001,1,10000}}, OldPrice = 500, NewPrice = 500, CheckUse = 1,},
	[MALL_ITEM_47] = { ID = MALL_ITEM_47, Class = 2, Item = {{"item",8001002,1,10000}}, OldPrice = 1000, NewPrice = 1000, CheckUse = 1,},
	[MALL_ITEM_48] = { ID = MALL_ITEM_48, Class = 2, Item = {{"item",8001003,1,10000}}, OldPrice = 2500, NewPrice = 2500, CheckUse = 1,},
	[MALL_ITEM_49] = { ID = MALL_ITEM_49, Class = 2, Item = {{"item",8001004,1,10000}}, OldPrice = 10000, NewPrice = 10000, CheckUse = 1,},
	[MALL_ITEM_50] = { ID = MALL_ITEM_50, Class = 2, Item = {{"item",8006001,1,10000}}, OldPrice = 800, NewPrice = 800, CheckUse = nil,},
	[MALL_ITEM_51] = { ID = MALL_ITEM_51, Class = 2, Item = {{"item",8006002,1,10000}}, OldPrice = 1500, NewPrice = 1500, CheckUse = nil,},
	[MALL_ITEM_52] = { ID = MALL_ITEM_52, Class = 2, Item = {{"item",8003001,1,10000}}, OldPrice = 250, NewPrice = 250, CheckUse = nil,},
	[MALL_ITEM_53] = { ID = MALL_ITEM_53, Class = 2, Item = {{"item",8003002,1,10000}}, OldPrice = 400, NewPrice = 400, CheckUse = nil,},
	[MALL_ITEM_54] = { ID = MALL_ITEM_54, Class = 2, Item = {{"item",8004001,1,10000}}, OldPrice = 250, NewPrice = 250, CheckUse = nil,},
	[MALL_ITEM_55] = { ID = MALL_ITEM_55, Class = 2, Item = {{"item",8004002,1,10000}}, OldPrice = 400, NewPrice = 400, CheckUse = nil,},
	[MALL_ITEM_56] = { ID = MALL_ITEM_56, Class = 2, Item = {{"item",8002001,1,10000}}, OldPrice = 200, NewPrice = 200, CheckUse = nil,},
	[MALL_ITEM_57] = { ID = MALL_ITEM_57, Class = 2, Item = {{"item",8002002,1,10000}}, OldPrice = 600, NewPrice = 600, CheckUse = nil,},
	[MALL_ITEM_58] = { ID = MALL_ITEM_58, Class = 2, Item = {{"item",8002003,1,10000}}, OldPrice = 1500, NewPrice = 1500, CheckUse = nil,},
	[MALL_ITEM_59] = { ID = MALL_ITEM_59, Class = 2, Item = {{"item",8002004,1,10000}}, OldPrice = 3000, NewPrice = 3000, CheckUse = nil,},
	[MALL_ITEM_60] = { ID = MALL_ITEM_60, Class = 2, Item = {{"item",8008001,1,10000}}, OldPrice = 200, NewPrice = 200, CheckUse = nil,},
	[MALL_ITEM_61] = { ID = MALL_ITEM_61, Class = 3, Item = {{"item",2011001,1,10000}}, OldPrice = 75, NewPrice = 75, CheckUse = nil,},
	[MALL_ITEM_62] = { ID = MALL_ITEM_62, Class = 3, Item = {{"item",2011002,1,10000}}, OldPrice = 100, NewPrice = 100, CheckUse = nil,},
	[MALL_ITEM_63] = { ID = MALL_ITEM_63, Class = 3, Item = {{"item",2011003,1,10000}}, OldPrice = 280, NewPrice = 280, CheckUse = nil,},
	[MALL_ITEM_64] = { ID = MALL_ITEM_64, Class = 3, Item = {{"item",1001022,1,10000}}, OldPrice = 100, NewPrice = 100, CheckUse = nil,},
	[MALL_ITEM_65] = { ID = MALL_ITEM_65, Class = 3, Item = {{"item",1001023,1,10000}}, OldPrice = 300, NewPrice = 300, CheckUse = nil,},
	[MALL_ITEM_66] = { ID = MALL_ITEM_66, Class = 3, Item = {{"item",1001024,1,10000}}, OldPrice = 1000, NewPrice = 1000, CheckUse = nil,},
	[MALL_ITEM_67] = { ID = MALL_ITEM_67, Class = 3, Item = {{"item",7023007,1,10000}}, OldPrice = 250, NewPrice = 250, CheckUse = nil,},
	[MALL_ITEM_68] = { ID = MALL_ITEM_68, Class = 3, Item = {{"item",7023008,1,10000}}, OldPrice = 1200, NewPrice = 1200, CheckUse = nil,},
	[MALL_ITEM_69] = { ID = MALL_ITEM_69, Class = 3, Item = {{"item",7023009,1,10000}}, OldPrice = 4000, NewPrice = 4000, CheckUse = nil,},
	[MALL_ITEM_70] = { ID = MALL_ITEM_70, Class = 4, Item = {{"item",7020001,1,10000}}, OldPrice = 15, NewPrice = 15, CheckUse = nil,},
	[MALL_ITEM_71] = { ID = MALL_ITEM_71, Class = 4, Item = {{"item",3001002,1,10000}}, OldPrice = 150, NewPrice = 150, CheckUse = nil,},
	[MALL_ITEM_72] = { ID = MALL_ITEM_72, Class = 4, Item = {{"item",7023002,1,10000}}, OldPrice = 40, NewPrice = 40, CheckUse = nil,},
	[MALL_ITEM_73] = { ID = MALL_ITEM_73, Class = 4, Item = {{"item",7024001,1,10000}}, OldPrice = 500, NewPrice = 500, CheckUse = nil,},
	[MALL_ITEM_74] = { ID = MALL_ITEM_74, Class = 4, Item = {{"item",4004001,1,10000}}, OldPrice = 200, NewPrice = 200, CheckUse = nil,},
	[MALL_ITEM_75] = { ID = MALL_ITEM_75, Class = 4, Item = {{"item",4005001,1,10000}}, OldPrice = 200, NewPrice = 200, CheckUse = nil,},
	[MALL_BUILD_QUEUE] = { ID = MALL_BUILD_QUEUE, Class = 4, Item = {{"item",8011001,1,10000}}, OldPrice = 200, NewPrice = 200, CheckUse = nil,},
	[MALL_ITEM_76] = { ID = MALL_ITEM_76, Class = 4, Item = {{"item",4006001,1,10000}}, OldPrice = 500, NewPrice = 500, CheckUse = nil,},
}
