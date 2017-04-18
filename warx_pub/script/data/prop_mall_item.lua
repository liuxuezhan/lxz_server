--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_mall_item = {

	[MALL_ITEMS_1] = { ID = MALL_ITEMS_1, Rate = 1250, Buy = {{"item",9001001,1,10000}}, Pay = {{12,17,60000}}, Notice = 0, Point = 5, Group = 1,},
	[MALL_ITEMS_2] = { ID = MALL_ITEMS_2, Rate = 1250, Buy = {{"item",9002001,1,10000}}, Pay = {{12,17,60000}}, Notice = 0, Point = 5, Group = 1,},
	[MALL_ITEMS_3] = { ID = MALL_ITEMS_3, Rate = 1250, Buy = {{"item",9003001,1,10000}}, Pay = {{12,17,60000}}, Notice = 0, Point = 6, Group = 1,},
	[MALL_ITEMS_4] = { ID = MALL_ITEMS_4, Rate = 1250, Buy = {{"item",9004001,1,10000}}, Pay = {{12,17,60000}}, Notice = 1, Point = 6, Group = 1,},
	[MALL_ITEMS_5] = { ID = MALL_ITEMS_5, Rate = 1250, Buy = {{"item",9005001,1,10000}}, Pay = {{12,17,120000}}, Notice = 0, Point = 10, Group = 1,},
	[MALL_ITEMS_6] = { ID = MALL_ITEMS_6, Rate = 1250, Buy = {{"item",9006001,1,10000}}, Pay = {{12,17,30000}}, Notice = 0, Point = 10, Group = 1,},
	[MALL_ITEMS_7] = { ID = MALL_ITEMS_7, Rate = 1250, Buy = {{"item",9007001,1,10000}}, Pay = {{12,17,60000}}, Notice = 0, Point = 14, Group = 1,},
	[MALL_ITEMS_8] = { ID = MALL_ITEMS_8, Rate = 1250, Buy = {{"item",9008001,1,10000}}, Pay = {{12,17,50000}}, Notice = 0, Point = 18, Group = 1,},
	[MALL_ITEMS_9] = { ID = MALL_ITEMS_9, Rate = 2000, Buy = {{"item",11001001,1,10000}}, Pay = {{12,17,80000}}, Notice = 0, Point = 18, Group = 2,},
	[MALL_ITEMS_10] = { ID = MALL_ITEMS_10, Rate = 2000, Buy = {{"item",11002001,1,10000}}, Pay = {{12,17,100000}}, Notice = 0, Point = 25, Group = 2,},
	[MALL_ITEMS_11] = { ID = MALL_ITEMS_11, Rate = 2000, Buy = {{"item",11003001,1,10000}}, Pay = {{12,17,150000}}, Notice = 0, Point = 25, Group = 2,},
	[MALL_ITEMS_12] = { ID = MALL_ITEMS_12, Rate = 2000, Buy = {{"item",11004001,1,10000}}, Pay = {{12,17,80000}}, Notice = 1, Point = 35, Group = 2,},
	[MALL_ITEMS_13] = { ID = MALL_ITEMS_13, Rate = 2000, Buy = {{"item",11005001,1,10000}}, Pay = {{12,17,80000}}, Notice = 1, Point = 40, Group = 2,},
	[MALL_ITEMS_14] = { ID = MALL_ITEMS_14, Rate = 833, Buy = {{"item",7001001,5,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_15] = { ID = MALL_ITEMS_15, Rate = 833, Buy = {{"item",7001002,2,10000}}, Pay = {{1,11,100}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_16] = { ID = MALL_ITEMS_16, Rate = 833, Buy = {{"item",7001003,1,10000}}, Pay = {{1,11,200}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_17] = { ID = MALL_ITEMS_17, Rate = 833, Buy = {{"item",7002001,5,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_18] = { ID = MALL_ITEMS_18, Rate = 833, Buy = {{"item",7002002,2,10000}}, Pay = {{1,11,100}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_19] = { ID = MALL_ITEMS_19, Rate = 833, Buy = {{"item",7002003,1,10000}}, Pay = {{1,11,200}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_20] = { ID = MALL_ITEMS_20, Rate = 833, Buy = {{"item",7003001,5,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_21] = { ID = MALL_ITEMS_21, Rate = 833, Buy = {{"item",7003002,2,10000}}, Pay = {{1,11,100}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_22] = { ID = MALL_ITEMS_22, Rate = 833, Buy = {{"item",7003003,1,10000}}, Pay = {{1,11,200}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_23] = { ID = MALL_ITEMS_23, Rate = 833, Buy = {{"item",7004001,5,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_24] = { ID = MALL_ITEMS_24, Rate = 833, Buy = {{"item",7004002,2,10000}}, Pay = {{1,11,100}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_25] = { ID = MALL_ITEMS_25, Rate = 837, Buy = {{"item",7004003,1,10000}}, Pay = {{1,11,200}}, Notice = 0, Point = 5, Group = 13,},
	[MALL_ITEMS_26] = { ID = MALL_ITEMS_26, Rate = 263, Buy = {{"item",7018001,1,10000}}, Pay = {{1,11,100}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_27] = { ID = MALL_ITEMS_27, Rate = 263, Buy = {{"item",3001001,1,10000}}, Pay = {{1,11,20}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_28] = { ID = MALL_ITEMS_28, Rate = 263, Buy = {{"item",3001002,1,10000}}, Pay = {{1,11,250}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_29] = { ID = MALL_ITEMS_29, Rate = 263, Buy = {{"item",3002001,1,10000}}, Pay = {{1,11,20}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_30] = { ID = MALL_ITEMS_30, Rate = 263, Buy = {{"item",3002002,1,10000}}, Pay = {{1,11,250}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_31] = { ID = MALL_ITEMS_31, Rate = 263, Buy = {{"item",3003001,1,10000}}, Pay = {{1,11,20}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_32] = { ID = MALL_ITEMS_32, Rate = 263, Buy = {{"item",3003002,1,10000}}, Pay = {{1,11,250}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_33] = { ID = MALL_ITEMS_33, Rate = 263, Buy = {{"item",3004001,1,10000}}, Pay = {{1,11,20}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_34] = { ID = MALL_ITEMS_34, Rate = 263, Buy = {{"item",3004002,1,10000}}, Pay = {{1,11,250}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_35] = { ID = MALL_ITEMS_35, Rate = 263, Buy = {{"item",3005001,1,10000}}, Pay = {{1,11,20}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_36] = { ID = MALL_ITEMS_36, Rate = 263, Buy = {{"item",3005002,1,10000}}, Pay = {{1,11,250}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_37] = { ID = MALL_ITEMS_37, Rate = 263, Buy = {{"item",2007001,1,10000}}, Pay = {{1,11,100}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_38] = { ID = MALL_ITEMS_38, Rate = 263, Buy = {{"item",2011002,1,10000}}, Pay = {{1,11,150}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_39] = { ID = MALL_ITEMS_39, Rate = 263, Buy = {{"item",2011003,1,10000}}, Pay = {{1,11,250}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_40] = { ID = MALL_ITEMS_40, Rate = 263, Buy = {{"item",6001001,2,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_41] = { ID = MALL_ITEMS_41, Rate = 263, Buy = {{"item",6002001,2,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_42] = { ID = MALL_ITEMS_42, Rate = 263, Buy = {{"item",6003001,2,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_43] = { ID = MALL_ITEMS_43, Rate = 263, Buy = {{"item",6004001,2,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_44] = { ID = MALL_ITEMS_44, Rate = 263, Buy = {{"item",6005001,2,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_45] = { ID = MALL_ITEMS_45, Rate = 263, Buy = {{"item",6006001,2,10000}}, Pay = {{1,11,50}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_46] = { ID = MALL_ITEMS_46, Rate = 263, Buy = {{"item",6001002,1,10000}}, Pay = {{1,11,150}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_47] = { ID = MALL_ITEMS_47, Rate = 263, Buy = {{"item",6002002,1,10000}}, Pay = {{1,11,150}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_48] = { ID = MALL_ITEMS_48, Rate = 263, Buy = {{"item",6003002,1,10000}}, Pay = {{1,11,150}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_49] = { ID = MALL_ITEMS_49, Rate = 263, Buy = {{"item",6004002,1,10000}}, Pay = {{1,11,150}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_50] = { ID = MALL_ITEMS_50, Rate = 263, Buy = {{"item",6005002,1,10000}}, Pay = {{1,11,150}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_51] = { ID = MALL_ITEMS_51, Rate = 263, Buy = {{"item",6006002,1,10000}}, Pay = {{1,11,150}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_52] = { ID = MALL_ITEMS_52, Rate = 263, Buy = {{"item",6001003,1,10000}}, Pay = {{1,11,400}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_53] = { ID = MALL_ITEMS_53, Rate = 263, Buy = {{"item",6002003,1,10000}}, Pay = {{1,11,400}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_54] = { ID = MALL_ITEMS_54, Rate = 263, Buy = {{"item",6003003,1,10000}}, Pay = {{1,11,400}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_55] = { ID = MALL_ITEMS_55, Rate = 263, Buy = {{"item",6004003,1,10000}}, Pay = {{1,11,400}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_56] = { ID = MALL_ITEMS_56, Rate = 263, Buy = {{"item",6005003,1,10000}}, Pay = {{1,11,400}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_57] = { ID = MALL_ITEMS_57, Rate = 263, Buy = {{"item",6006003,1,10000}}, Pay = {{1,11,400}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_58] = { ID = MALL_ITEMS_58, Rate = 263, Buy = {{"item",6001001,8,10000}}, Pay = {{1,11,350}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_59] = { ID = MALL_ITEMS_59, Rate = 263, Buy = {{"item",6002001,8,10000}}, Pay = {{1,11,350}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_60] = { ID = MALL_ITEMS_60, Rate = 263, Buy = {{"item",6003001,8,10000}}, Pay = {{1,11,350}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_61] = { ID = MALL_ITEMS_61, Rate = 263, Buy = {{"item",6004001,8,10000}}, Pay = {{1,11,350}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_62] = { ID = MALL_ITEMS_62, Rate = 263, Buy = {{"item",6005001,8,10000}}, Pay = {{1,11,350}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_63] = { ID = MALL_ITEMS_63, Rate = 269, Buy = {{"item",6006001,8,10000}}, Pay = {{1,11,350}}, Notice = 0, Point = 5, Group = 14,},
	[MALL_ITEMS_64] = { ID = MALL_ITEMS_64, Rate = 5000, Buy = {{"item",4002109,5,10000}}, Pay = {{1,11,500}}, Notice = 0, Point = 5, Group = 12,},
	[MALL_ITEMS_65] = { ID = MALL_ITEMS_65, Rate = 5000, Buy = {{"item",4002108,5,10000}}, Pay = {{1,11,500}}, Notice = 0, Point = 5, Group = 12,},
	[MALL_ITEMS_66] = { ID = MALL_ITEMS_66, Rate = 10000, Buy = {{"item",4002014,1,10000}}, Pay = {{1,11,400}}, Notice = 0, Point = 5, Group = 11,},
	[MALL_ITEMS_67] = { ID = MALL_ITEMS_67, Rate = 263, Buy = {{"item",7018001,1,10000}}, Pay = {{1,18,100}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_68] = { ID = MALL_ITEMS_68, Rate = 263, Buy = {{"item",3001001,1,10000}}, Pay = {{1,18,20}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_69] = { ID = MALL_ITEMS_69, Rate = 263, Buy = {{"item",3001002,1,10000}}, Pay = {{1,18,250}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_70] = { ID = MALL_ITEMS_70, Rate = 263, Buy = {{"item",3002001,1,10000}}, Pay = {{1,18,20}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_71] = { ID = MALL_ITEMS_71, Rate = 263, Buy = {{"item",3002002,1,10000}}, Pay = {{1,18,250}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_72] = { ID = MALL_ITEMS_72, Rate = 263, Buy = {{"item",3003001,1,10000}}, Pay = {{1,18,20}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_73] = { ID = MALL_ITEMS_73, Rate = 263, Buy = {{"item",3003002,1,10000}}, Pay = {{1,18,250}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_74] = { ID = MALL_ITEMS_74, Rate = 263, Buy = {{"item",3004001,1,10000}}, Pay = {{1,18,20}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_75] = { ID = MALL_ITEMS_75, Rate = 263, Buy = {{"item",3004002,1,10000}}, Pay = {{1,18,250}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_76] = { ID = MALL_ITEMS_76, Rate = 263, Buy = {{"item",3005001,1,10000}}, Pay = {{1,18,20}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_77] = { ID = MALL_ITEMS_77, Rate = 263, Buy = {{"item",3005002,1,10000}}, Pay = {{1,18,250}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_78] = { ID = MALL_ITEMS_78, Rate = 263, Buy = {{"item",2007001,1,10000}}, Pay = {{1,18,100}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_79] = { ID = MALL_ITEMS_79, Rate = 263, Buy = {{"item",2011002,1,10000}}, Pay = {{1,18,150}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_80] = { ID = MALL_ITEMS_80, Rate = 263, Buy = {{"item",2011003,1,10000}}, Pay = {{1,18,250}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_81] = { ID = MALL_ITEMS_81, Rate = 263, Buy = {{"item",6001001,2,10000}}, Pay = {{1,18,50}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_82] = { ID = MALL_ITEMS_82, Rate = 263, Buy = {{"item",6002001,2,10000}}, Pay = {{1,18,50}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_83] = { ID = MALL_ITEMS_83, Rate = 263, Buy = {{"item",6003001,2,10000}}, Pay = {{1,18,50}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_84] = { ID = MALL_ITEMS_84, Rate = 263, Buy = {{"item",6004001,2,10000}}, Pay = {{1,18,50}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_85] = { ID = MALL_ITEMS_85, Rate = 263, Buy = {{"item",6005001,2,10000}}, Pay = {{1,18,50}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_86] = { ID = MALL_ITEMS_86, Rate = 263, Buy = {{"item",6006001,2,10000}}, Pay = {{1,18,50}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_87] = { ID = MALL_ITEMS_87, Rate = 263, Buy = {{"item",6001002,1,10000}}, Pay = {{1,18,150}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_88] = { ID = MALL_ITEMS_88, Rate = 263, Buy = {{"item",6002002,1,10000}}, Pay = {{1,18,150}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_89] = { ID = MALL_ITEMS_89, Rate = 263, Buy = {{"item",6003002,1,10000}}, Pay = {{1,18,150}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_90] = { ID = MALL_ITEMS_90, Rate = 263, Buy = {{"item",6004002,1,10000}}, Pay = {{1,18,150}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_91] = { ID = MALL_ITEMS_91, Rate = 263, Buy = {{"item",6005002,1,10000}}, Pay = {{1,18,150}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_92] = { ID = MALL_ITEMS_92, Rate = 263, Buy = {{"item",6006002,1,10000}}, Pay = {{1,18,150}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_93] = { ID = MALL_ITEMS_93, Rate = 263, Buy = {{"item",6001003,1,10000}}, Pay = {{1,18,400}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_94] = { ID = MALL_ITEMS_94, Rate = 263, Buy = {{"item",6002003,1,10000}}, Pay = {{1,18,400}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_95] = { ID = MALL_ITEMS_95, Rate = 263, Buy = {{"item",6003003,1,10000}}, Pay = {{1,18,400}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_96] = { ID = MALL_ITEMS_96, Rate = 263, Buy = {{"item",6004003,1,10000}}, Pay = {{1,18,400}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_97] = { ID = MALL_ITEMS_97, Rate = 263, Buy = {{"item",6005003,1,10000}}, Pay = {{1,18,400}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_98] = { ID = MALL_ITEMS_98, Rate = 263, Buy = {{"item",6006003,1,10000}}, Pay = {{1,18,400}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_99] = { ID = MALL_ITEMS_99, Rate = 263, Buy = {{"item",6001001,8,10000}}, Pay = {{1,18,350}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_100] = { ID = MALL_ITEMS_100, Rate = 263, Buy = {{"item",6002001,8,10000}}, Pay = {{1,18,350}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_101] = { ID = MALL_ITEMS_101, Rate = 263, Buy = {{"item",6003001,8,10000}}, Pay = {{1,18,350}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_102] = { ID = MALL_ITEMS_102, Rate = 263, Buy = {{"item",6004001,8,10000}}, Pay = {{1,18,350}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_103] = { ID = MALL_ITEMS_103, Rate = 263, Buy = {{"item",6005001,8,10000}}, Pay = {{1,18,350}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_104] = { ID = MALL_ITEMS_104, Rate = 269, Buy = {{"item",6006001,8,10000}}, Pay = {{1,18,350}}, Notice = 0, Point = 5, Group = 27,},
	[MALL_ITEMS_105] = { ID = MALL_ITEMS_105, Rate = 1000, Buy = {{"item",5001302,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_106] = { ID = MALL_ITEMS_106, Rate = 1000, Buy = {{"item",5001304,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_107] = { ID = MALL_ITEMS_107, Rate = 1000, Buy = {{"item",5001307,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_108] = { ID = MALL_ITEMS_108, Rate = 1000, Buy = {{"item",5001309,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_109] = { ID = MALL_ITEMS_109, Rate = 1000, Buy = {{"item",5001312,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_110] = { ID = MALL_ITEMS_110, Rate = 1000, Buy = {{"item",5001322,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_111] = { ID = MALL_ITEMS_111, Rate = 1000, Buy = {{"item",5001335,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_112] = { ID = MALL_ITEMS_112, Rate = 1000, Buy = {{"item",5001337,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_113] = { ID = MALL_ITEMS_113, Rate = 1000, Buy = {{"item",5001339,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_114] = { ID = MALL_ITEMS_114, Rate = 1000, Buy = {{"item",5002002,5,10000}}, Pay = {{1,18,1800}}, Notice = 0, Point = 5, Group = 21,},
	[MALL_ITEMS_115] = { ID = MALL_ITEMS_115, Rate = 1000, Buy = {{"item",5001301,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_116] = { ID = MALL_ITEMS_116, Rate = 1000, Buy = {{"item",5001303,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_117] = { ID = MALL_ITEMS_117, Rate = 1000, Buy = {{"item",5001306,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_118] = { ID = MALL_ITEMS_118, Rate = 1000, Buy = {{"item",5001308,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_119] = { ID = MALL_ITEMS_119, Rate = 1000, Buy = {{"item",5001311,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_120] = { ID = MALL_ITEMS_120, Rate = 1000, Buy = {{"item",5001313,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_121] = { ID = MALL_ITEMS_121, Rate = 1000, Buy = {{"item",5001334,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_122] = { ID = MALL_ITEMS_122, Rate = 1000, Buy = {{"item",5001336,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_123] = { ID = MALL_ITEMS_123, Rate = 1000, Buy = {{"item",5001338,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_124] = { ID = MALL_ITEMS_124, Rate = 1000, Buy = {{"item",5002002,5,10000}}, Pay = {{1,18,1800}}, Notice = 0, Point = 5, Group = 22,},
	[MALL_ITEMS_125] = { ID = MALL_ITEMS_125, Rate = 589, Buy = {{"item",5001202,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_126] = { ID = MALL_ITEMS_126, Rate = 589, Buy = {{"item",5001204,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_127] = { ID = MALL_ITEMS_127, Rate = 589, Buy = {{"item",5001212,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_128] = { ID = MALL_ITEMS_128, Rate = 589, Buy = {{"item",5001222,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_129] = { ID = MALL_ITEMS_129, Rate = 588, Buy = {{"item",5001235,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_130] = { ID = MALL_ITEMS_130, Rate = 588, Buy = {{"item",5001237,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_131] = { ID = MALL_ITEMS_131, Rate = 588, Buy = {{"item",5001302,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_132] = { ID = MALL_ITEMS_132, Rate = 588, Buy = {{"item",5001304,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_133] = { ID = MALL_ITEMS_133, Rate = 588, Buy = {{"item",5001307,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_134] = { ID = MALL_ITEMS_134, Rate = 588, Buy = {{"item",5001309,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_135] = { ID = MALL_ITEMS_135, Rate = 588, Buy = {{"item",5001312,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_136] = { ID = MALL_ITEMS_136, Rate = 588, Buy = {{"item",5001322,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_137] = { ID = MALL_ITEMS_137, Rate = 588, Buy = {{"item",5001335,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_138] = { ID = MALL_ITEMS_138, Rate = 588, Buy = {{"item",5001337,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_139] = { ID = MALL_ITEMS_139, Rate = 588, Buy = {{"item",5001339,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_140] = { ID = MALL_ITEMS_140, Rate = 588, Buy = {{"item",5002002,5,10000}}, Pay = {{1,18,1800}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_141] = { ID = MALL_ITEMS_141, Rate = 588, Buy = {{"item",5002002,2,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 23,},
	[MALL_ITEMS_142] = { ID = MALL_ITEMS_142, Rate = 589, Buy = {{"item",5001201,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_143] = { ID = MALL_ITEMS_143, Rate = 589, Buy = {{"item",5001203,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_144] = { ID = MALL_ITEMS_144, Rate = 589, Buy = {{"item",5001211,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_145] = { ID = MALL_ITEMS_145, Rate = 589, Buy = {{"item",5001213,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_146] = { ID = MALL_ITEMS_146, Rate = 588, Buy = {{"item",5001234,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_147] = { ID = MALL_ITEMS_147, Rate = 588, Buy = {{"item",5001236,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_148] = { ID = MALL_ITEMS_148, Rate = 588, Buy = {{"item",5001301,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_149] = { ID = MALL_ITEMS_149, Rate = 588, Buy = {{"item",5001303,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_150] = { ID = MALL_ITEMS_150, Rate = 588, Buy = {{"item",5001306,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_151] = { ID = MALL_ITEMS_151, Rate = 588, Buy = {{"item",5001308,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_152] = { ID = MALL_ITEMS_152, Rate = 588, Buy = {{"item",5001311,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_153] = { ID = MALL_ITEMS_153, Rate = 588, Buy = {{"item",5001313,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_154] = { ID = MALL_ITEMS_154, Rate = 588, Buy = {{"item",5001334,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_155] = { ID = MALL_ITEMS_155, Rate = 588, Buy = {{"item",5001336,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_156] = { ID = MALL_ITEMS_156, Rate = 588, Buy = {{"item",5001338,1,10000}}, Pay = {{1,18,2500}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_157] = { ID = MALL_ITEMS_157, Rate = 588, Buy = {{"item",5002002,5,10000}}, Pay = {{1,18,1800}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_158] = { ID = MALL_ITEMS_158, Rate = 588, Buy = {{"item",5002002,2,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 24,},
	[MALL_ITEMS_159] = { ID = MALL_ITEMS_159, Rate = 715, Buy = {{"item",5001202,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_160] = { ID = MALL_ITEMS_160, Rate = 715, Buy = {{"item",5001204,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_161] = { ID = MALL_ITEMS_161, Rate = 715, Buy = {{"item",5001212,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_162] = { ID = MALL_ITEMS_162, Rate = 715, Buy = {{"item",5001222,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_163] = { ID = MALL_ITEMS_163, Rate = 715, Buy = {{"item",5001235,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_164] = { ID = MALL_ITEMS_164, Rate = 715, Buy = {{"item",5001237,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_165] = { ID = MALL_ITEMS_165, Rate = 715, Buy = {{"item",5001201,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_166] = { ID = MALL_ITEMS_166, Rate = 715, Buy = {{"item",5001203,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_167] = { ID = MALL_ITEMS_167, Rate = 715, Buy = {{"item",5001211,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_168] = { ID = MALL_ITEMS_168, Rate = 715, Buy = {{"item",5001213,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_169] = { ID = MALL_ITEMS_169, Rate = 715, Buy = {{"item",5001234,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_170] = { ID = MALL_ITEMS_170, Rate = 715, Buy = {{"item",5001236,1,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_171] = { ID = MALL_ITEMS_171, Rate = 1420, Buy = {{"item",5002002,2,10000}}, Pay = {{1,18,750}}, Notice = 0, Point = 5, Group = 25,},
	[MALL_ITEMS_172] = { ID = MALL_ITEMS_172, Rate = 1000, Buy = {{"item",5001102,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_173] = { ID = MALL_ITEMS_173, Rate = 1000, Buy = {{"item",5001104,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_174] = { ID = MALL_ITEMS_174, Rate = 1000, Buy = {{"item",5001135,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_175] = { ID = MALL_ITEMS_175, Rate = 1000, Buy = {{"item",5001137,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_176] = { ID = MALL_ITEMS_176, Rate = 1000, Buy = {{"item",5001101,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_177] = { ID = MALL_ITEMS_177, Rate = 1000, Buy = {{"item",5001103,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_178] = { ID = MALL_ITEMS_178, Rate = 1000, Buy = {{"item",5001134,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_179] = { ID = MALL_ITEMS_179, Rate = 1000, Buy = {{"item",5001136,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_180] = { ID = MALL_ITEMS_180, Rate = 2000, Buy = {{"item",5002001,1,10000}}, Pay = {{1,18,75}}, Notice = 0, Point = 5, Group = 26,},
	[MALL_ITEMS_181] = { ID = MALL_ITEMS_181, Rate = 1000, Buy = {{"item",7018001,1,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_182] = { ID = MALL_ITEMS_182, Rate = 900, Buy = {{"item",3001001,1,10000}}, Pay = {{1,19,20}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_183] = { ID = MALL_ITEMS_183, Rate = 900, Buy = {{"item",3001002,1,10000}}, Pay = {{1,19,250}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_184] = { ID = MALL_ITEMS_184, Rate = 900, Buy = {{"item",3002001,1,10000}}, Pay = {{1,19,20}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_185] = { ID = MALL_ITEMS_185, Rate = 900, Buy = {{"item",3002002,1,10000}}, Pay = {{1,19,250}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_186] = { ID = MALL_ITEMS_186, Rate = 900, Buy = {{"item",3003001,1,10000}}, Pay = {{1,19,20}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_187] = { ID = MALL_ITEMS_187, Rate = 900, Buy = {{"item",3003002,1,10000}}, Pay = {{1,19,250}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_188] = { ID = MALL_ITEMS_188, Rate = 900, Buy = {{"item",3004001,1,10000}}, Pay = {{1,19,20}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_189] = { ID = MALL_ITEMS_189, Rate = 900, Buy = {{"item",3004002,1,10000}}, Pay = {{1,19,250}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_190] = { ID = MALL_ITEMS_190, Rate = 900, Buy = {{"item",3005001,1,10000}}, Pay = {{1,19,20}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_191] = { ID = MALL_ITEMS_191, Rate = 900, Buy = {{"item",3005002,1,10000}}, Pay = {{1,19,250}}, Notice = 0, Point = 5, Group = 40,},
	[MALL_ITEMS_192] = { ID = MALL_ITEMS_192, Rate = 1666, Buy = {{"item",6001001,5,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 39,},
	[MALL_ITEMS_193] = { ID = MALL_ITEMS_193, Rate = 1666, Buy = {{"item",6002001,5,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 39,},
	[MALL_ITEMS_194] = { ID = MALL_ITEMS_194, Rate = 1667, Buy = {{"item",6003001,5,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 39,},
	[MALL_ITEMS_195] = { ID = MALL_ITEMS_195, Rate = 1667, Buy = {{"item",6004001,5,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 39,},
	[MALL_ITEMS_196] = { ID = MALL_ITEMS_196, Rate = 1667, Buy = {{"item",6005001,5,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 39,},
	[MALL_ITEMS_197] = { ID = MALL_ITEMS_197, Rate = 1667, Buy = {{"item",6006001,5,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 39,},
	[MALL_ITEMS_198] = { ID = MALL_ITEMS_198, Rate = 1666, Buy = {{"item",6001002,1,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 38,},
	[MALL_ITEMS_199] = { ID = MALL_ITEMS_199, Rate = 1666, Buy = {{"item",6002002,1,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 38,},
	[MALL_ITEMS_200] = { ID = MALL_ITEMS_200, Rate = 1667, Buy = {{"item",6003002,1,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 38,},
	[MALL_ITEMS_201] = { ID = MALL_ITEMS_201, Rate = 1667, Buy = {{"item",6004002,1,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 38,},
	[MALL_ITEMS_202] = { ID = MALL_ITEMS_202, Rate = 1667, Buy = {{"item",6005002,1,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 38,},
	[MALL_ITEMS_203] = { ID = MALL_ITEMS_203, Rate = 1667, Buy = {{"item",6006002,1,10000}}, Pay = {{1,19,50}}, Notice = 0, Point = 5, Group = 38,},
	[MALL_ITEMS_204] = { ID = MALL_ITEMS_204, Rate = 10000, Buy = {{"item",6001003,1,10000}}, Pay = {{1,19,180}}, Notice = 0, Point = 5, Group = 37,},
	[MALL_ITEMS_205] = { ID = MALL_ITEMS_205, Rate = 10000, Buy = {{"item",6002003,1,10000}}, Pay = {{1,19,180}}, Notice = 0, Point = 5, Group = 36,},
	[MALL_ITEMS_206] = { ID = MALL_ITEMS_206, Rate = 10000, Buy = {{"item",6003003,1,10000}}, Pay = {{1,19,180}}, Notice = 0, Point = 5, Group = 35,},
	[MALL_ITEMS_207] = { ID = MALL_ITEMS_207, Rate = 10000, Buy = {{"item",6004003,1,10000}}, Pay = {{1,19,180}}, Notice = 0, Point = 5, Group = 34,},
	[MALL_ITEMS_208] = { ID = MALL_ITEMS_208, Rate = 10000, Buy = {{"item",6005003,1,10000}}, Pay = {{1,19,180}}, Notice = 0, Point = 5, Group = 33,},
	[MALL_ITEMS_209] = { ID = MALL_ITEMS_209, Rate = 10000, Buy = {{"item",6006003,1,10000}}, Pay = {{1,19,180}}, Notice = 0, Point = 5, Group = 32,},
	[MALL_ITEMS_210] = { ID = MALL_ITEMS_210, Rate = 1666, Buy = {{"item",6001004,1,10000}}, Pay = {{1,19,600}}, Notice = 0, Point = 5, Group = 31,},
	[MALL_ITEMS_211] = { ID = MALL_ITEMS_211, Rate = 1666, Buy = {{"item",6002004,1,10000}}, Pay = {{1,19,600}}, Notice = 0, Point = 5, Group = 31,},
	[MALL_ITEMS_212] = { ID = MALL_ITEMS_212, Rate = 1667, Buy = {{"item",6003004,1,10000}}, Pay = {{1,19,600}}, Notice = 0, Point = 5, Group = 31,},
	[MALL_ITEMS_213] = { ID = MALL_ITEMS_213, Rate = 1667, Buy = {{"item",6004004,1,10000}}, Pay = {{1,19,600}}, Notice = 0, Point = 5, Group = 31,},
	[MALL_ITEMS_214] = { ID = MALL_ITEMS_214, Rate = 1667, Buy = {{"item",6005004,1,10000}}, Pay = {{1,19,600}}, Notice = 0, Point = 5, Group = 31,},
	[MALL_ITEMS_215] = { ID = MALL_ITEMS_215, Rate = 1667, Buy = {{"item",6006004,1,10000}}, Pay = {{1,19,600}}, Notice = 0, Point = 5, Group = 31,},
}
