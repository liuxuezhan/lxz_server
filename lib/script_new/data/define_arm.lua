--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

ARM_BU_1 = 1001
ARM_BU_2 = 1002
ARM_BU_3 = 1003
ARM_BU_4 = 1004
ARM_BU_5 = 1005
ARM_BU_6 = 1006
ARM_BU_7 = 1007
ARM_BU_8 = 1008
ARM_BU_9 = 1009
ARM_BU_10 = 1010
ARM_QI_1 = 2001
ARM_QI_2 = 2002
ARM_QI_3 = 2003
ARM_QI_4 = 2004
ARM_QI_5 = 2005
ARM_QI_6 = 2006
ARM_QI_7 = 2007
ARM_QI_8 = 2008
ARM_QI_9 = 2009
ARM_QI_10 = 2010
ARM_GONG_1 = 3001
ARM_GONG_2 = 3002
ARM_GONG_3 = 3003
ARM_GONG_4 = 3004
ARM_GONG_5 = 3005
ARM_GONG_6 = 3006
ARM_GONG_7 = 3007
ARM_GONG_8 = 3008
ARM_GONG_9 = 3009
ARM_GONG_10 = 3010
ARM_CHE_1 = 4001
ARM_CHE_2 = 4002
ARM_CHE_3 = 4003
ARM_CHE_4 = 4004
ARM_CHE_5 = 4005
ARM_CHE_6 = 4006
ARM_CHE_7 = 4007
ARM_CHE_8 = 4008
ARM_CHE_9 = 4009
ARM_CHE_10 = 4010
BOSS_PUTONG_BU_1 = 1001001
BOSS_PUTONG_BU_2 = 1001002
BOSS_PUTONG_BU_3 = 1001003
BOSS_PUTONG_BU_4 = 1001004
BOSS_PUTONG_BU_5 = 1001005
BOSS_PUTONG_BU_6 = 1001006
BOSS_PUTONG_BU_7 = 1001007
BOSS_PUTONG_BU_8 = 1001008
BOSS_PUTONG_QI_1 = 1002001
BOSS_PUTONG_QI_2 = 1002002
BOSS_PUTONG_QI_3 = 1002003
BOSS_PUTONG_QI_4 = 1002004
BOSS_PUTONG_QI_5 = 1002005
BOSS_PUTONG_QI_6 = 1002006
BOSS_PUTONG_QI_7 = 1002007
BOSS_PUTONG_QI_8 = 1002008
BOSS_PUTONG_GONG_1 = 1003001
BOSS_PUTONG_GONG_2 = 1003002
BOSS_PUTONG_GONG_3 = 1003003
BOSS_PUTONG_GONG_4 = 1003004
BOSS_PUTONG_GONG_5 = 1003005
BOSS_PUTONG_GONG_6 = 1003006
BOSS_PUTONG_GONG_7 = 1003007
BOSS_PUTONG_GONG_8 = 1003008
BOSS_PUTONG_CHE_3 = 1004003
BOSS_PUTONG_CHE_4 = 1004004
BOSS_PUTONG_CHE_5 = 1004005
BOSS_PUTONG_CHE_6 = 1004006
BOSS_PUTONG_CHE_7 = 1004007
BOSS_PUTONG_CHE_8 = 1004008
BOSS_JINGYING1_BU_8 = 11001008
BOSS_JINGYING1_QI_8 = 11002008
BOSS_JINGYING1_GONG_8 = 11003008
BOSS_JINGYING1_CHE_8 = 11004008
BOSS_JINGYING2_BU_8 = 12001008
BOSS_JINGYING2_QI_8 = 12002008
BOSS_JINGYING2_GONG_8 = 12003008
BOSS_JINGYING2_CHE_8 = 12004008
BOSS_JINGYING3_BU_8 = 13001008
BOSS_JINGYING3_QI_8 = 13002008
BOSS_JINGYING3_GONG_8 = 13003008
BOSS_JINGYING3_CHE_8 = 13004008
BOSS_JINGYING4_BU_8 = 14001008
BOSS_JINGYING4_QI_8 = 14002008
BOSS_JINGYING4_GONG_8 = 14003008
BOSS_JINGYING4_CHE_8 = 14004008
BOSS_JINGYING5_BU_8 = 15001008
BOSS_JINGYING5_QI_8 = 15002008
BOSS_JINGYING5_GONG_8 = 15003008
BOSS_JINGYING5_CHE_8 = 15004008
BOSS_JINGYING6_BU_8 = 16001008
BOSS_JINGYING6_QI_8 = 16002008
BOSS_JINGYING6_GONG_8 = 16003008
BOSS_JINGYING6_CHE_8 = 16004008
BOSS_SHOULING1_BU_9 = 21001009
BOSS_SHOULING1_QI_9 = 21002009
BOSS_SHOULING1_GONG_9 = 21003009
BOSS_SHOULING1_CHE_9 = 21004009
BOSS_SHOULING2_BU_9 = 22001009
BOSS_SHOULING2_QI_9 = 22002009
BOSS_SHOULING2_GONG_9 = 22003009
BOSS_SHOULING2_CHE_9 = 22004009
BOSS_SHOULING3_BU_9 = 23001009
BOSS_SHOULING3_QI_9 = 23002009
BOSS_SHOULING3_GONG_9 = 23003009
BOSS_SHOULING3_CHE_9 = 23004009
BOSS_SHOULING4_BU_9 = 24001009
BOSS_SHOULING4_QI_9 = 24002009
BOSS_SHOULING4_GONG_9 = 24003009
BOSS_SHOULING4_CHE_9 = 24004009
BOSS_SHOULING5_BU_9 = 25001009
BOSS_SHOULING5_QI_9 = 25002009
BOSS_SHOULING5_GONG_9 = 25003009
BOSS_SHOULING5_CHE_9 = 25004009
BOSS_CHAOJI1_BU_10 = 31001010
BOSS_CHAOJI1_QI_10 = 31002010
BOSS_CHAOJI1_GONG_10 = 31003010
BOSS_CHAOJI1_CHE_10 = 31004010
BOSS_CHAOJI2_BU_10 = 32001010
BOSS_CHAOJI2_QI_10 = 32002010
BOSS_CHAOJI2_GONG_10 = 32003010
BOSS_CHAOJI2_CHE_10 = 32004010
BOSS_CHAOJI3_BU_10 = 33001010
BOSS_CHAOJI3_QI_10 = 33002010
BOSS_CHAOJI3_GONG_10 = 33003010
BOSS_CHAOJI3_CHE_10 = 33004010