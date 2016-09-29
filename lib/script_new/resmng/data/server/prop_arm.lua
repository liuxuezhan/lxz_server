--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_arm = {

	[ARM_BU_1] = { ID = ARM_BU_1, mode = 1, lv = 1, atk = 24, def = 10, hp = 520, speed = 11, weight = 9, consume = 0.21, pow = 1, trainSpeed = 20, cons = {{1,1,1}},},
	[ARM_BU_2] = { ID = ARM_BU_2, mode = 1, lv = 2, atk = 33.6, def = 14, hp = 728, speed = 11, weight = 9, consume = 0.42, pow = 1.4, trainSpeed = 24, cons = {{1,1,2}},},
	[ARM_BU_3] = { ID = ARM_BU_3, mode = 1, lv = 3, atk = 45.6, def = 19, hp = 988, speed = 11, weight = 10, consume = 0.62, pow = 1.9, trainSpeed = 32, cons = {{1,1,3}},},
	[ARM_BU_4] = { ID = ARM_BU_4, mode = 1, lv = 4, atk = 60, def = 25, hp = 1300, speed = 11, weight = 10, consume = 0.83, pow = 2.5, trainSpeed = 42, cons = {{1,1,4}},},
	[ARM_BU_5] = { ID = ARM_BU_5, mode = 1, lv = 5, atk = 76.8, def = 32, hp = 1664, speed = 11, weight = 11, consume = 1.04, pow = 3.2, trainSpeed = 56, cons = {{1,1,5}},},
	[ARM_BU_6] = { ID = ARM_BU_6, mode = 1, lv = 6, atk = 96, def = 40, hp = 2080, speed = 11, weight = 11, consume = 1.25, pow = 4, trainSpeed = 72, cons = {{1,1,6}},},
	[ARM_BU_7] = { ID = ARM_BU_7, mode = 1, lv = 7, atk = 117.6, def = 49, hp = 2548, speed = 11, weight = 12, consume = 1.46, pow = 4.9, trainSpeed = 90, cons = {{1,1,7}},},
	[ARM_BU_8] = { ID = ARM_BU_8, mode = 1, lv = 8, atk = 141.6, def = 59, hp = 3068, speed = 11, weight = 12, consume = 1.67, pow = 5.9, trainSpeed = 110, cons = {{1,1,8}},},
	[ARM_BU_9] = { ID = ARM_BU_9, mode = 1, lv = 9, atk = 168, def = 70, hp = 3640, speed = 11, weight = 13, consume = 1.88, pow = 7, trainSpeed = 132, cons = {{1,1,9}},},
	[ARM_BU_10] = { ID = ARM_BU_10, mode = 1, lv = 10, atk = 196.8, def = 82, hp = 4264, speed = 11, weight = 13, consume = 2.08, pow = 8.2, trainSpeed = 156, cons = {{1,1,10}},},
	[ARM_QI_1] = { ID = ARM_QI_1, mode = 2, lv = 1, atk = 31, def = 8, hp = 480, speed = 15, weight = 6, consume = 0.21, pow = 1, trainSpeed = 20, cons = {{1,1,1}},},
	[ARM_QI_2] = { ID = ARM_QI_2, mode = 2, lv = 2, atk = 43.4, def = 11.2, hp = 672, speed = 15, weight = 6, consume = 0.42, pow = 1.4, trainSpeed = 24, cons = {{1,1,2}},},
	[ARM_QI_3] = { ID = ARM_QI_3, mode = 2, lv = 3, atk = 58.9, def = 15.2, hp = 912, speed = 15, weight = 7, consume = 0.62, pow = 1.9, trainSpeed = 32, cons = {{1,1,3}},},
	[ARM_QI_4] = { ID = ARM_QI_4, mode = 2, lv = 4, atk = 77.5, def = 20, hp = 1200, speed = 15, weight = 7, consume = 0.83, pow = 2.5, trainSpeed = 42, cons = {{1,1,4}},},
	[ARM_QI_5] = { ID = ARM_QI_5, mode = 2, lv = 5, atk = 99.2, def = 25.6, hp = 1536, speed = 15, weight = 8, consume = 1.04, pow = 3.2, trainSpeed = 56, cons = {{1,1,5}},},
	[ARM_QI_6] = { ID = ARM_QI_6, mode = 2, lv = 6, atk = 124, def = 32, hp = 1920, speed = 15, weight = 8, consume = 1.25, pow = 4, trainSpeed = 72, cons = {{1,1,6}},},
	[ARM_QI_7] = { ID = ARM_QI_7, mode = 2, lv = 7, atk = 151.9, def = 39.2, hp = 2352, speed = 15, weight = 9, consume = 1.46, pow = 4.9, trainSpeed = 90, cons = {{1,1,7}},},
	[ARM_QI_8] = { ID = ARM_QI_8, mode = 2, lv = 8, atk = 182.9, def = 47.2, hp = 2832, speed = 15, weight = 9, consume = 1.67, pow = 5.9, trainSpeed = 110, cons = {{1,1,8}},},
	[ARM_QI_9] = { ID = ARM_QI_9, mode = 2, lv = 9, atk = 217, def = 56, hp = 3360, speed = 15, weight = 10, consume = 1.88, pow = 7, trainSpeed = 132, cons = {{1,1,9}},},
	[ARM_QI_10] = { ID = ARM_QI_10, mode = 2, lv = 10, atk = 254.2, def = 65.6, hp = 3936.0, speed = 15, weight = 10, consume = 2.08, pow = 8.2, trainSpeed = 156, cons = {{1,1,10}},},
	[ARM_GONG_1] = { ID = ARM_GONG_1, mode = 3, lv = 1, atk = 33, def = 9, hp = 390, speed = 10, weight = 8, consume = 0.21, pow = 1, trainSpeed = 20, cons = {{1,1,1}},},
	[ARM_GONG_2] = { ID = ARM_GONG_2, mode = 3, lv = 2, atk = 46.2, def = 12.6, hp = 546, speed = 10, weight = 8, consume = 0.42, pow = 1.4, trainSpeed = 24, cons = {{1,1,2}},},
	[ARM_GONG_3] = { ID = ARM_GONG_3, mode = 3, lv = 3, atk = 62.7, def = 17.1, hp = 741, speed = 10, weight = 9, consume = 0.62, pow = 1.9, trainSpeed = 32, cons = {{1,1,3}},},
	[ARM_GONG_4] = { ID = ARM_GONG_4, mode = 3, lv = 4, atk = 82.5, def = 22.5, hp = 975, speed = 10, weight = 9, consume = 0.83, pow = 2.5, trainSpeed = 42, cons = {{1,1,4}},},
	[ARM_GONG_5] = { ID = ARM_GONG_5, mode = 3, lv = 5, atk = 105.6, def = 28.8, hp = 1248, speed = 10, weight = 10, consume = 1.04, pow = 3.2, trainSpeed = 56, cons = {{1,1,5}},},
	[ARM_GONG_6] = { ID = ARM_GONG_6, mode = 3, lv = 6, atk = 132, def = 36, hp = 1560, speed = 10, weight = 10, consume = 1.25, pow = 4, trainSpeed = 72, cons = {{1,1,6}},},
	[ARM_GONG_7] = { ID = ARM_GONG_7, mode = 3, lv = 7, atk = 161.7, def = 44.1, hp = 1911, speed = 10, weight = 11, consume = 1.46, pow = 4.9, trainSpeed = 90, cons = {{1,1,7}},},
	[ARM_GONG_8] = { ID = ARM_GONG_8, mode = 3, lv = 8, atk = 194.7, def = 53.1, hp = 2301, speed = 10, weight = 11, consume = 1.67, pow = 5.9, trainSpeed = 110, cons = {{1,1,8}},},
	[ARM_GONG_9] = { ID = ARM_GONG_9, mode = 3, lv = 9, atk = 231, def = 63, hp = 2730, speed = 10, weight = 12, consume = 1.88, pow = 7, trainSpeed = 132, cons = {{1,1,9}},},
	[ARM_GONG_10] = { ID = ARM_GONG_10, mode = 3, lv = 10, atk = 270.6, def = 73.8, hp = 3198.0, speed = 10, weight = 12, consume = 2.08, pow = 8.2, trainSpeed = 156, cons = {{1,1,10}},},
	[ARM_CHE_1] = { ID = ARM_CHE_1, mode = 4, lv = 1, atk = 36, def = 12, hp = 180, speed = 7, weight = 22, consume = 0.21, pow = 1, trainSpeed = 20, cons = {{1,1,1}},},
	[ARM_CHE_2] = { ID = ARM_CHE_2, mode = 4, lv = 2, atk = 50.4, def = 16.8, hp = 252.0, speed = 7, weight = 22, consume = 0.42, pow = 1.4, trainSpeed = 24, cons = {{1,1,2}},},
	[ARM_CHE_3] = { ID = ARM_CHE_3, mode = 4, lv = 3, atk = 68.4, def = 22.8, hp = 342, speed = 7, weight = 23, consume = 0.62, pow = 1.9, trainSpeed = 32, cons = {{1,1,3}},},
	[ARM_CHE_4] = { ID = ARM_CHE_4, mode = 4, lv = 4, atk = 90, def = 30, hp = 450, speed = 7, weight = 23, consume = 0.83, pow = 2.5, trainSpeed = 42, cons = {{1,1,4}},},
	[ARM_CHE_5] = { ID = ARM_CHE_5, mode = 4, lv = 5, atk = 115.2, def = 38.4, hp = 576, speed = 7, weight = 24, consume = 1.04, pow = 3.2, trainSpeed = 56, cons = {{1,1,5}},},
	[ARM_CHE_6] = { ID = ARM_CHE_6, mode = 4, lv = 6, atk = 144, def = 48, hp = 720, speed = 7, weight = 24, consume = 1.25, pow = 4, trainSpeed = 72, cons = {{1,1,6}},},
	[ARM_CHE_7] = { ID = ARM_CHE_7, mode = 4, lv = 7, atk = 176.4, def = 58.8, hp = 882, speed = 7, weight = 25, consume = 1.46, pow = 4.9, trainSpeed = 90, cons = {{1,1,7}},},
	[ARM_CHE_8] = { ID = ARM_CHE_8, mode = 4, lv = 8, atk = 212.4, def = 70.8, hp = 1062, speed = 7, weight = 26, consume = 1.67, pow = 5.9, trainSpeed = 110, cons = {{1,1,8}},},
	[ARM_CHE_9] = { ID = ARM_CHE_9, mode = 4, lv = 9, atk = 252, def = 84, hp = 1260, speed = 7, weight = 27, consume = 1.88, pow = 7, trainSpeed = 132, cons = {{1,1,9}},},
	[ARM_CHE_10] = { ID = ARM_CHE_10, mode = 4, lv = 10, atk = 295.2, def = 98.4, hp = 1476.0, speed = 7, weight = 28, consume = 2.08, pow = 8.2, trainSpeed = 156, cons = {{1,1,10}},},
}
