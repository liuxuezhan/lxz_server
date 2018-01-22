--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_language_cfg = {

	[LANGUAGE_DEF_0] = { ID = LANGUAGE_DEF_0, LanKey = "af", LanOffline = "af", TencentID = 6, Text = COMMON_LANTXT_0,},
	[LANGUAGE_DEF_1] = { ID = LANGUAGE_DEF_1, LanKey = "ar", LanOffline = "ar", TencentID = 3, Text = COMMON_LANTXT_1,},
	[LANGUAGE_DEF_2] = { ID = LANGUAGE_DEF_2, LanKey = "eu", LanOffline = "eu", TencentID = 6, Text = COMMON_LANTXT_2,},
	[LANGUAGE_DEF_3] = { ID = LANGUAGE_DEF_3, LanKey = "be", LanOffline = "be", TencentID = 13, Text = COMMON_LANTXT_3,},
	[LANGUAGE_DEF_4] = { ID = LANGUAGE_DEF_4, LanKey = "bg", LanOffline = "bg", TencentID = 18, Text = COMMON_LANTXT_4,},
	[LANGUAGE_DEF_5] = { ID = LANGUAGE_DEF_5, LanKey = "ca", LanOffline = "ca", TencentID = 4, Text = COMMON_LANTXT_5,},
	[LANGUAGE_DEF_7] = { ID = LANGUAGE_DEF_7, LanKey = "cs", LanOffline = "cs", TencentID = 24, Text = COMMON_LANTXT_7,},
	[LANGUAGE_DEF_8] = { ID = LANGUAGE_DEF_8, LanKey = "da", LanOffline = "da", TencentID = 25, Text = COMMON_LANTXT_8,},
	[LANGUAGE_DEF_9] = { ID = LANGUAGE_DEF_9, LanKey = "nl", LanOffline = "nl", TencentID = 57, Text = COMMON_LANTXT_9,},
	[LANGUAGE_DEF_10] = { ID = LANGUAGE_DEF_10, LanKey = "en", LanOffline = "en", TencentID = 6, Text = COMMON_LANTXT_10,},
	[LANGUAGE_DEF_11] = { ID = LANGUAGE_DEF_11, LanKey = "et", LanOffline = "et", TencentID = 27, Text = COMMON_LANTXT_11,},
	[LANGUAGE_DEF_12] = { ID = LANGUAGE_DEF_12, LanKey = "fo", LanOffline = "fo", TencentID = 6, Text = COMMON_LANTXT_12,},
	[LANGUAGE_DEF_13] = { ID = LANGUAGE_DEF_13, LanKey = "fi", LanOffline = "fi", TencentID = 30, Text = COMMON_LANTXT_13,},
	[LANGUAGE_DEF_14] = { ID = LANGUAGE_DEF_14, LanKey = "fr", LanOffline = "fr", TencentID = 14, Text = COMMON_LANTXT_14,},
	[LANGUAGE_DEF_15] = { ID = LANGUAGE_DEF_15, LanKey = "de", LanOffline = "de", TencentID = 10, Text = COMMON_LANTXT_15,},
	[LANGUAGE_DEF_16] = { ID = LANGUAGE_DEF_16, LanKey = "el", LanOffline = "el", TencentID = 23, Text = COMMON_LANTXT_16,},
	[LANGUAGE_DEF_17] = { ID = LANGUAGE_DEF_17, LanKey = "he", LanOffline = "he", TencentID = 37, Text = COMMON_LANTXT_17,},
	[LANGUAGE_DEF_18] = { ID = LANGUAGE_DEF_18, LanKey = "hu", LanOffline = "hu", TencentID = 32, Text = COMMON_LANTXT_18,},
	[LANGUAGE_DEF_19] = { ID = LANGUAGE_DEF_19, LanKey = "is", LanOffline = "is", TencentID = 33, Text = COMMON_LANTXT_19,},
	[LANGUAGE_DEF_20] = { ID = LANGUAGE_DEF_20, LanKey = "id", LanOffline = "id", TencentID = 35, Text = COMMON_LANTXT_20,},
	[LANGUAGE_DEF_21] = { ID = LANGUAGE_DEF_21, LanKey = "it", LanOffline = "it", TencentID = 38, Text = COMMON_LANTXT_21,},
	[LANGUAGE_DEF_22] = { ID = LANGUAGE_DEF_22, LanKey = "ja", LanOffline = "ja", TencentID = 39, Text = COMMON_LANTXT_22,},
	[LANGUAGE_DEF_23] = { ID = LANGUAGE_DEF_23, LanKey = "ko", LanOffline = "ko", TencentID = 41, Text = COMMON_LANTXT_23,},
	[LANGUAGE_DEF_24] = { ID = LANGUAGE_DEF_24, LanKey = "lv", LanOffline = "lv", TencentID = 44, Text = COMMON_LANTXT_24,},
	[LANGUAGE_DEF_25] = { ID = LANGUAGE_DEF_25, LanKey = "lt", LanOffline = "lt", TencentID = 45, Text = COMMON_LANTXT_25,},
	[LANGUAGE_DEF_26] = { ID = LANGUAGE_DEF_26, LanKey = "no", LanOffline = "no", TencentID = 58, Text = COMMON_LANTXT_26,},
	[LANGUAGE_DEF_27] = { ID = LANGUAGE_DEF_27, LanKey = "pl", LanOffline = "pl", TencentID = 61, Text = COMMON_LANTXT_27,},
	[LANGUAGE_DEF_28] = { ID = LANGUAGE_DEF_28, LanKey = "pt", LanOffline = "pt", TencentID = 5, Text = COMMON_LANTXT_28,},
	[LANGUAGE_DEF_29] = { ID = LANGUAGE_DEF_29, LanKey = "ro", LanOffline = "ro", TencentID = 62, Text = COMMON_LANTXT_29,},
	[LANGUAGE_DEF_30] = { ID = LANGUAGE_DEF_30, LanKey = "ru", LanOffline = "ru", TencentID = 63, Text = COMMON_LANTXT_30,},
	[LANGUAGE_DEF_31] = { ID = LANGUAGE_DEF_31, LanKey = "sr", LanOffline = "sr", TencentID = 6, Text = COMMON_LANTXT_31,},
	[LANGUAGE_DEF_32] = { ID = LANGUAGE_DEF_32, LanKey = "sk", LanOffline = "sk", TencentID = 66, Text = COMMON_LANTXT_32,},
	[LANGUAGE_DEF_33] = { ID = LANGUAGE_DEF_33, LanKey = "sl", LanOffline = "sl", TencentID = 67, Text = COMMON_LANTXT_33,},
	[LANGUAGE_DEF_34] = { ID = LANGUAGE_DEF_34, LanKey = "es", LanOffline = "es", TencentID = 7, Text = COMMON_LANTXT_34,},
	[LANGUAGE_DEF_35] = { ID = LANGUAGE_DEF_35, LanKey = "sv", LanOffline = "sv", TencentID = 71, Text = COMMON_LANTXT_35,},
	[LANGUAGE_DEF_36] = { ID = LANGUAGE_DEF_36, LanKey = "th", LanOffline = "th", TencentID = 74, Text = COMMON_LANTXT_36,},
	[LANGUAGE_DEF_37] = { ID = LANGUAGE_DEF_37, LanKey = "tr", LanOffline = "tr", TencentID = 76, Text = COMMON_LANTXT_37,},
	[LANGUAGE_DEF_38] = { ID = LANGUAGE_DEF_38, LanKey = "uk", LanOffline = "uk", TencentID = 79, Text = COMMON_LANTXT_38,},
	[LANGUAGE_DEF_39] = { ID = LANGUAGE_DEF_39, LanKey = "vi", LanOffline = "vi", TencentID = 83, Text = COMMON_LANTXT_39,},
	[LANGUAGE_DEF_40] = { ID = LANGUAGE_DEF_40, LanKey = "zh-CN", LanOffline = "zhCN", TencentID = 21, Text = COMMON_LANTXT_40,},
	[LANGUAGE_DEF_41] = { ID = LANGUAGE_DEF_41, LanKey = "zh-TW", LanOffline = "zhTW", TencentID = 84, Text = COMMON_LANTXT_41,},
}
