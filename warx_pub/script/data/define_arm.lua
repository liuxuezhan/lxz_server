--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

ARM_BU_1_HX = 1001001
ARM_BU_2_HX = 1001002
ARM_BU_3_HX = 1001003
ARM_BU_4_HX = 1001004
ARM_BU_5_HX = 1001005
ARM_BU_6_HX = 1001006
ARM_BU_7_HX = 1001007
ARM_BU_8_HX = 1001008
ARM_BU_9_HX = 1001009
ARM_BU_10_HX = 1001010
ARM_QI_1_HX = 1002001
ARM_QI_2_HX = 1002002
ARM_QI_3_HX = 1002003
ARM_QI_4_HX = 1002004
ARM_QI_5_HX = 1002005
ARM_QI_6_HX = 1002006
ARM_QI_7_HX = 1002007
ARM_QI_8_HX = 1002008
ARM_QI_9_HX = 1002009
ARM_QI_10_HX = 1002010
ARM_GONG_1_HX = 1003001
ARM_GONG_2_HX = 1003002
ARM_GONG_3_HX = 1003003
ARM_GONG_4_HX = 1003004
ARM_GONG_5_HX = 1003005
ARM_GONG_6_HX = 1003006
ARM_GONG_7_HX = 1003007
ARM_GONG_8_HX = 1003008
ARM_GONG_9_HX = 1003009
ARM_GONG_10_HX = 1003010
ARM_CHE_1_HX = 1004001
ARM_CHE_2_HX = 1004002
ARM_CHE_3_HX = 1004003
ARM_CHE_4_HX = 1004004
ARM_CHE_5_HX = 1004005
ARM_CHE_6_HX = 1004006
ARM_CHE_7_HX = 1004007
ARM_CHE_8_HX = 1004008
ARM_CHE_9_HX = 1004009
ARM_CHE_10_HX = 1004010
ARM_BU_1_BS = 2001001
ARM_BU_2_BS = 2001002
ARM_BU_3_BS = 2001003
ARM_BU_4_BS = 2001004
ARM_BU_5_BS = 2001005
ARM_BU_6_BS = 2001006
ARM_BU_7_BS = 2001007
ARM_BU_8_BS = 2001008
ARM_BU_9_BS = 2001009
ARM_BU_10_BS = 2001010
ARM_QI_1_BS = 2002001
ARM_QI_2_BS = 2002002
ARM_QI_3_BS = 2002003
ARM_QI_4_BS = 2002004
ARM_QI_5_BS = 2002005
ARM_QI_6_BS = 2002006
ARM_QI_7_BS = 2002007
ARM_QI_8_BS = 2002008
ARM_QI_9_BS = 2002009
ARM_QI_10_BS = 2002010
ARM_GONG_1_BS = 2003001
ARM_GONG_2_BS = 2003002
ARM_GONG_3_BS = 2003003
ARM_GONG_4_BS = 2003004
ARM_GONG_5_BS = 2003005
ARM_GONG_6_BS = 2003006
ARM_GONG_7_BS = 2003007
ARM_GONG_8_BS = 2003008
ARM_GONG_9_BS = 2003009
ARM_GONG_10_BS = 2003010
ARM_CHE_1_BS = 2004001
ARM_CHE_2_BS = 2004002
ARM_CHE_3_BS = 2004003
ARM_CHE_4_BS = 2004004
ARM_CHE_5_BS = 2004005
ARM_CHE_6_BS = 2004006
ARM_CHE_7_BS = 2004007
ARM_CHE_8_BS = 2004008
ARM_CHE_9_BS = 2004009
ARM_CHE_10_BS = 2004010
ARM_BU_1_LM = 3001001
ARM_BU_2_LM = 3001002
ARM_BU_3_LM = 3001003
ARM_BU_4_LM = 3001004
ARM_BU_5_LM = 3001005
ARM_BU_6_LM = 3001006
ARM_BU_7_LM = 3001007
ARM_BU_8_LM = 3001008
ARM_BU_9_LM = 3001009
ARM_BU_10_LM = 3001010
ARM_QI_1_LM = 3002001
ARM_QI_2_LM = 3002002
ARM_QI_3_LM = 3002003
ARM_QI_4_LM = 3002004
ARM_QI_5_LM = 3002005
ARM_QI_6_LM = 3002006
ARM_QI_7_LM = 3002007
ARM_QI_8_LM = 3002008
ARM_QI_9_LM = 3002009
ARM_QI_10_LM = 3002010
ARM_GONG_1_LM = 3003001
ARM_GONG_2_LM = 3003002
ARM_GONG_3_LM = 3003003
ARM_GONG_4_LM = 3003004
ARM_GONG_5_LM = 3003005
ARM_GONG_6_LM = 3003006
ARM_GONG_7_LM = 3003007
ARM_GONG_8_LM = 3003008
ARM_GONG_9_LM = 3003009
ARM_GONG_10_LM = 3003010
ARM_CHE_1_LM = 3004001
ARM_CHE_2_LM = 3004002
ARM_CHE_3_LM = 3004003
ARM_CHE_4_LM = 3004004
ARM_CHE_5_LM = 3004005
ARM_CHE_6_LM = 3004006
ARM_CHE_7_LM = 3004007
ARM_CHE_8_LM = 3004008
ARM_CHE_9_LM = 3004009
ARM_CHE_10_LM = 3004010
ARM_BU_1_SLF = 4001001
ARM_BU_2_SLF = 4001002
ARM_BU_3_SLF = 4001003
ARM_BU_4_SLF = 4001004
ARM_BU_5_SLF = 4001005
ARM_BU_6_SLF = 4001006
ARM_BU_7_SLF = 4001007
ARM_BU_8_SLF = 4001008
ARM_BU_9_SLF = 4001009
ARM_BU_10_SLF = 4001010
ARM_QI_1_SLF = 4002001
ARM_QI_2_SLF = 4002002
ARM_QI_3_SLF = 4002003
ARM_QI_4_SLF = 4002004
ARM_QI_5_SLF = 4002005
ARM_QI_6_SLF = 4002006
ARM_QI_7_SLF = 4002007
ARM_QI_8_SLF = 4002008
ARM_QI_9_SLF = 4002009
ARM_QI_10_SLF = 4002010
ARM_GONG_1_SLF = 4003001
ARM_GONG_2_SLF = 4003002
ARM_GONG_3_SLF = 4003003
ARM_GONG_4_SLF = 4003004
ARM_GONG_5_SLF = 4003005
ARM_GONG_6_SLF = 4003006
ARM_GONG_7_SLF = 4003007
ARM_GONG_8_SLF = 4003008
ARM_GONG_9_SLF = 4003009
ARM_GONG_10_SLF = 4003010
ARM_CHE_1_SLF = 4004001
ARM_CHE_2_SLF = 4004002
ARM_CHE_3_SLF = 4004003
ARM_CHE_4_SLF = 4004004
ARM_CHE_5_SLF = 4004005
ARM_CHE_6_SLF = 4004006
ARM_CHE_7_SLF = 4004007
ARM_CHE_8_SLF = 4004008
ARM_CHE_9_SLF = 4004009
ARM_CHE_10_SLF = 4004010
BOSS_BU_1 = 9001001
BOSS_BU_2 = 9001002
BOSS_BU_3 = 9001003
BOSS_BU_4 = 9001004
BOSS_BU_5 = 9001005
BOSS_BU_6 = 9001006
BOSS_BU_7 = 9001007
BOSS_BU_8 = 9001008
BOSS_BU_9 = 9001009
BOSS_BU_10 = 9001010
BOSS_QI_1 = 9002001
BOSS_QI_2 = 9002002
BOSS_QI_3 = 9002003
BOSS_QI_4 = 9002004
BOSS_QI_5 = 9002005
BOSS_QI_6 = 9002006
BOSS_QI_7 = 9002007
BOSS_QI_8 = 9002008
BOSS_QI_9 = 9002009
BOSS_QI_10 = 9002010
BOSS_GONG_1 = 9003001
BOSS_GONG_2 = 9003002
BOSS_GONG_3 = 9003003
BOSS_GONG_4 = 9003004
BOSS_GONG_5 = 9003005
BOSS_GONG_6 = 9003006
BOSS_GONG_7 = 9003007
BOSS_GONG_8 = 9003008
BOSS_GONG_9 = 9003009
BOSS_GONG_10 = 9003010
BOSS_CHE_1 = 9004001
BOSS_CHE_2 = 9004002
BOSS_CHE_3 = 9004003
BOSS_CHE_4 = 9004004
BOSS_CHE_5 = 9004005
BOSS_CHE_6 = 9004006
BOSS_CHE_7 = 9004007
BOSS_CHE_8 = 9004008
BOSS_CHE_9 = 9004009
BOSS_CHE_10 = 9004010
BOSS_TASK_BU_1 = 40001001
BOSS_TASK_BU_2 = 40001002
BOSS_TASK_BU_3 = 40001003
BOSS_TASK_BU_4 = 40001004
BOSS_TASK_BU_5 = 40001005
BOSS_TASK_BU_6 = 40001006
BOSS_TASK_BU_7 = 40001007
BOSS_TASK_BU_8 = 40001008
BOSS_TASK_BU_9 = 40001009
BOSS_TASK_BU_10 = 40001010
BOSS_TASK_QI_1 = 40002001
BOSS_TASK_QI_2 = 40002002
BOSS_TASK_QI_3 = 40002003
BOSS_TASK_QI_4 = 40002004
BOSS_TASK_QI_5 = 40002005
BOSS_TASK_QI_6 = 40002006
BOSS_TASK_QI_7 = 40002007
BOSS_TASK_QI_8 = 40002008
BOSS_TASK_QI_9 = 40002009
BOSS_TASK_QI_10 = 40002010
BOSS_TASK_GONG_1 = 40003001
BOSS_TASK_GONG_2 = 40003002
BOSS_TASK_GONG_3 = 40003003
BOSS_TASK_GONG_4 = 40003004
BOSS_TASK_GONG_5 = 40003005
BOSS_TASK_GONG_6 = 40003006
BOSS_TASK_GONG_7 = 40003007
BOSS_TASK_GONG_8 = 40003008
BOSS_TASK_GONG_9 = 40003009
BOSS_TASK_GONG_10 = 40003010
BOSS_TASK_CHE_1 = 40004001
BOSS_TASK_CHE_2 = 40004002
BOSS_TASK_CHE_3 = 40004003
BOSS_TASK_CHE_4 = 40004004
BOSS_TASK_CHE_5 = 40004005
BOSS_TASK_CHE_6 = 40004006
BOSS_TASK_CHE_7 = 40004007
BOSS_TASK_CHE_8 = 40004008
BOSS_TASK_CHE_9 = 40004009
BOSS_TASK_CHE_10 = 40004010
