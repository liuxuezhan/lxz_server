--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

BUILD_CASTLE_1 = 1
BUILD_CASTLE_2 = 2
BUILD_CASTLE_3 = 3
BUILD_CASTLE_4 = 4
BUILD_CASTLE_5 = 5
BUILD_CASTLE_6 = 6
BUILD_CASTLE_7 = 7
BUILD_CASTLE_8 = 8
BUILD_CASTLE_9 = 9
BUILD_CASTLE_10 = 10
BUILD_CASTLE_11 = 11
BUILD_CASTLE_12 = 12
BUILD_CASTLE_13 = 13
BUILD_CASTLE_14 = 14
BUILD_CASTLE_15 = 15
BUILD_CASTLE_16 = 16
BUILD_CASTLE_17 = 17
BUILD_CASTLE_18 = 18
BUILD_CASTLE_19 = 19
BUILD_CASTLE_20 = 20
BUILD_CASTLE_21 = 21
BUILD_CASTLE_22 = 22
BUILD_CASTLE_23 = 23
BUILD_CASTLE_24 = 24
BUILD_CASTLE_25 = 25
BUILD_CASTLE_26 = 26
BUILD_CASTLE_27 = 27
BUILD_CASTLE_28 = 28
BUILD_CASTLE_29 = 29
BUILD_CASTLE_30 = 30
BUILD_ALTAR_1 = 1001
BUILD_ALTAR_2 = 1002
BUILD_ALTAR_3 = 1003
BUILD_ALTAR_4 = 1004
BUILD_ALTAR_5 = 1005
BUILD_ALTAR_6 = 1006
BUILD_ALTAR_7 = 1007
BUILD_ALTAR_8 = 1008
BUILD_ALTAR_9 = 1009
BUILD_ALTAR_10 = 1010
BUILD_ALTAR_11 = 1011
BUILD_ALTAR_12 = 1012
BUILD_ALTAR_13 = 1013
BUILD_ALTAR_14 = 1014
BUILD_ALTAR_15 = 1015
BUILD_ALTAR_16 = 1016
BUILD_ALTAR_17 = 1017
BUILD_ALTAR_18 = 1018
BUILD_ALTAR_19 = 1019
BUILD_ALTAR_20 = 1020
BUILD_ALTAR_21 = 1021
BUILD_ALTAR_22 = 1022
BUILD_ALTAR_23 = 1023
BUILD_ALTAR_24 = 1024
BUILD_ALTAR_25 = 1025
BUILD_ALTAR_26 = 1026
BUILD_ALTAR_27 = 1027
BUILD_ALTAR_28 = 1028
BUILD_ALTAR_29 = 1029
BUILD_ALTAR_30 = 1030
BUILD_WALLS_1 = 2001
BUILD_WALLS_2 = 2002
BUILD_WALLS_3 = 2003
BUILD_WALLS_4 = 2004
BUILD_WALLS_5 = 2005
BUILD_WALLS_6 = 2006
BUILD_WALLS_7 = 2007
BUILD_WALLS_8 = 2008
BUILD_WALLS_9 = 2009
BUILD_WALLS_10 = 2010
BUILD_WALLS_11 = 2011
BUILD_WALLS_12 = 2012
BUILD_WALLS_13 = 2013
BUILD_WALLS_14 = 2014
BUILD_WALLS_15 = 2015
BUILD_WALLS_16 = 2016
BUILD_WALLS_17 = 2017
BUILD_WALLS_18 = 2018
BUILD_WALLS_19 = 2019
BUILD_WALLS_20 = 2020
BUILD_WALLS_21 = 2021
BUILD_WALLS_22 = 2022
BUILD_WALLS_23 = 2023
BUILD_WALLS_24 = 2024
BUILD_WALLS_25 = 2025
BUILD_WALLS_26 = 2026
BUILD_WALLS_27 = 2027
BUILD_WALLS_28 = 2028
BUILD_WALLS_29 = 2029
BUILD_WALLS_30 = 2030
BUILD_DAILYQUEST_1 = 3001
BUILD_STOREHOUSE_1 = 4001
BUILD_STOREHOUSE_2 = 4002
BUILD_STOREHOUSE_3 = 4003
BUILD_STOREHOUSE_4 = 4004
BUILD_STOREHOUSE_5 = 4005
BUILD_STOREHOUSE_6 = 4006
BUILD_STOREHOUSE_7 = 4007
BUILD_STOREHOUSE_8 = 4008
BUILD_STOREHOUSE_9 = 4009
BUILD_STOREHOUSE_10 = 4010
BUILD_STOREHOUSE_11 = 4011
BUILD_STOREHOUSE_12 = 4012
BUILD_STOREHOUSE_13 = 4013
BUILD_STOREHOUSE_14 = 4014
BUILD_STOREHOUSE_15 = 4015
BUILD_STOREHOUSE_16 = 4016
BUILD_STOREHOUSE_17 = 4017
BUILD_STOREHOUSE_18 = 4018
BUILD_STOREHOUSE_19 = 4019
BUILD_STOREHOUSE_20 = 4020
BUILD_STOREHOUSE_21 = 4021
BUILD_STOREHOUSE_22 = 4022
BUILD_STOREHOUSE_23 = 4023
BUILD_STOREHOUSE_24 = 4024
BUILD_STOREHOUSE_25 = 4025
BUILD_STOREHOUSE_26 = 4026
BUILD_STOREHOUSE_27 = 4027
BUILD_STOREHOUSE_28 = 4028
BUILD_STOREHOUSE_29 = 4029
BUILD_STOREHOUSE_30 = 4030
BUILD_MARKET_1 = 5001
BUILD_MARKET_2 = 5002
BUILD_MARKET_3 = 5003
BUILD_MARKET_4 = 5004
BUILD_MARKET_5 = 5005
BUILD_MARKET_6 = 5006
BUILD_MARKET_7 = 5007
BUILD_MARKET_8 = 5008
BUILD_MARKET_9 = 5009
BUILD_MARKET_10 = 5010
BUILD_MARKET_11 = 5011
BUILD_MARKET_12 = 5012
BUILD_MARKET_13 = 5013
BUILD_MARKET_14 = 5014
BUILD_MARKET_15 = 5015
BUILD_MARKET_16 = 5016
BUILD_MARKET_17 = 5017
BUILD_MARKET_18 = 5018
BUILD_MARKET_19 = 5019
BUILD_MARKET_20 = 5020
BUILD_MARKET_21 = 5021
BUILD_MARKET_22 = 5022
BUILD_MARKET_23 = 5023
BUILD_MARKET_24 = 5024
BUILD_MARKET_25 = 5025
BUILD_MARKET_26 = 5026
BUILD_MARKET_27 = 5027
BUILD_MARKET_28 = 5028
BUILD_MARKET_29 = 5029
BUILD_MARKET_30 = 5030
BUILD_BLACKMARKET_1 = 6001
BUILD_RESOURCESMARKET_1 = 7001
BUILD_RESOURCESMARKET_2 = 7002
BUILD_RESOURCESMARKET_3 = 7003
BUILD_RESOURCESMARKET_4 = 7004
BUILD_RESOURCESMARKET_5 = 7005
BUILD_RESOURCESMARKET_6 = 7006
BUILD_RESOURCESMARKET_7 = 7007
BUILD_RESOURCESMARKET_8 = 7008
BUILD_RESOURCESMARKET_9 = 7009
BUILD_RESOURCESMARKET_10 = 7010
BUILD_RESOURCESMARKET_11 = 7011
BUILD_RESOURCESMARKET_12 = 7012
BUILD_RESOURCESMARKET_13 = 7013
BUILD_RESOURCESMARKET_14 = 7014
BUILD_RESOURCESMARKET_15 = 7015
BUILD_RESOURCESMARKET_16 = 7016
BUILD_RESOURCESMARKET_17 = 7017
BUILD_RESOURCESMARKET_18 = 7018
BUILD_RESOURCESMARKET_19 = 7019
BUILD_RESOURCESMARKET_20 = 7020
BUILD_RESOURCESMARKET_21 = 7021
BUILD_RESOURCESMARKET_22 = 7022
BUILD_RESOURCESMARKET_23 = 7023
BUILD_RESOURCESMARKET_24 = 7024
BUILD_RESOURCESMARKET_25 = 7025
BUILD_RESOURCESMARKET_26 = 7026
BUILD_RESOURCESMARKET_27 = 7027
BUILD_RESOURCESMARKET_28 = 7028
BUILD_RESOURCESMARKET_29 = 7029
BUILD_RESOURCESMARKET_30 = 7030
BUILD_PRISON_1 = 8001
BUILD_PRISON_2 = 8002
BUILD_PRISON_3 = 8003
BUILD_PRISON_4 = 8004
BUILD_PRISON_5 = 8005
BUILD_PRISON_6 = 8006
BUILD_PRISON_7 = 8007
BUILD_PRISON_8 = 8008
BUILD_PRISON_9 = 8009
BUILD_PRISON_10 = 8010
BUILD_PRISON_11 = 8011
BUILD_PRISON_12 = 8012
BUILD_PRISON_13 = 8013
BUILD_PRISON_14 = 8014
BUILD_PRISON_15 = 8015
BUILD_PRISON_16 = 8016
BUILD_PRISON_17 = 8017
BUILD_PRISON_18 = 8018
BUILD_PRISON_19 = 8019
BUILD_PRISON_20 = 8020
BUILD_PRISON_21 = 8021
BUILD_PRISON_22 = 8022
BUILD_PRISON_23 = 8023
BUILD_PRISON_24 = 8024
BUILD_PRISON_25 = 8025
BUILD_PRISON_26 = 8026
BUILD_PRISON_27 = 8027
BUILD_PRISON_28 = 8028
BUILD_PRISON_29 = 8029
BUILD_PRISON_30 = 8030
BUILD_FORGE_1 = 9001
BUILD_FORGE_2 = 9002
BUILD_FORGE_3 = 9003
BUILD_FORGE_4 = 9004
BUILD_FORGE_5 = 9005
BUILD_FORGE_6 = 9006
BUILD_FORGE_7 = 9007
BUILD_FORGE_8 = 9008
BUILD_FORGE_9 = 9009
BUILD_FORGE_10 = 9010
BUILD_FORGE_11 = 9011
BUILD_FORGE_12 = 9012
BUILD_FORGE_13 = 9013
BUILD_FORGE_14 = 9014
BUILD_FORGE_15 = 9015
BUILD_FORGE_16 = 9016
BUILD_FORGE_17 = 9017
BUILD_FORGE_18 = 9018
BUILD_FORGE_19 = 9019
BUILD_FORGE_20 = 9020
BUILD_FORGE_21 = 9021
BUILD_FORGE_22 = 9022
BUILD_FORGE_23 = 9023
BUILD_FORGE_24 = 9024
BUILD_FORGE_25 = 9025
BUILD_FORGE_26 = 9026
BUILD_FORGE_27 = 9027
BUILD_FORGE_28 = 9028
BUILD_FORGE_29 = 9029
BUILD_FORGE_30 = 9030
BUILD_ACADEMY_1 = 10001
BUILD_ACADEMY_2 = 10002
BUILD_ACADEMY_3 = 10003
BUILD_ACADEMY_4 = 10004
BUILD_ACADEMY_5 = 10005
BUILD_ACADEMY_6 = 10006
BUILD_ACADEMY_7 = 10007
BUILD_ACADEMY_8 = 10008
BUILD_ACADEMY_9 = 10009
BUILD_ACADEMY_10 = 10010
BUILD_ACADEMY_11 = 10011
BUILD_ACADEMY_12 = 10012
BUILD_ACADEMY_13 = 10013
BUILD_ACADEMY_14 = 10014
BUILD_ACADEMY_15 = 10015
BUILD_ACADEMY_16 = 10016
BUILD_ACADEMY_17 = 10017
BUILD_ACADEMY_18 = 10018
BUILD_ACADEMY_19 = 10019
BUILD_ACADEMY_20 = 10020
BUILD_ACADEMY_21 = 10021
BUILD_ACADEMY_22 = 10022
BUILD_ACADEMY_23 = 10023
BUILD_ACADEMY_24 = 10024
BUILD_ACADEMY_25 = 10025
BUILD_ACADEMY_26 = 10026
BUILD_ACADEMY_27 = 10027
BUILD_ACADEMY_28 = 10028
BUILD_ACADEMY_29 = 10029
BUILD_ACADEMY_30 = 10030
BUILD_HALLOFHERO_1 = 11001
BUILD_EMBASSY_1 = 12001
BUILD_EMBASSY_2 = 12002
BUILD_EMBASSY_3 = 12003
BUILD_EMBASSY_4 = 12004
BUILD_EMBASSY_5 = 12005
BUILD_EMBASSY_6 = 12006
BUILD_EMBASSY_7 = 12007
BUILD_EMBASSY_8 = 12008
BUILD_EMBASSY_9 = 12009
BUILD_EMBASSY_10 = 12010
BUILD_EMBASSY_11 = 12011
BUILD_EMBASSY_12 = 12012
BUILD_EMBASSY_13 = 12013
BUILD_EMBASSY_14 = 12014
BUILD_EMBASSY_15 = 12015
BUILD_EMBASSY_16 = 12016
BUILD_EMBASSY_17 = 12017
BUILD_EMBASSY_18 = 12018
BUILD_EMBASSY_19 = 12019
BUILD_EMBASSY_20 = 12020
BUILD_EMBASSY_21 = 12021
BUILD_EMBASSY_22 = 12022
BUILD_EMBASSY_23 = 12023
BUILD_EMBASSY_24 = 12024
BUILD_EMBASSY_25 = 12025
BUILD_EMBASSY_26 = 12026
BUILD_EMBASSY_27 = 12027
BUILD_EMBASSY_28 = 12028
BUILD_EMBASSY_29 = 12029
BUILD_EMBASSY_30 = 12030
BUILD_HALLOFWAR_1 = 13001
BUILD_HALLOFWAR_2 = 13002
BUILD_HALLOFWAR_3 = 13003
BUILD_HALLOFWAR_4 = 13004
BUILD_HALLOFWAR_5 = 13005
BUILD_HALLOFWAR_6 = 13006
BUILD_HALLOFWAR_7 = 13007
BUILD_HALLOFWAR_8 = 13008
BUILD_HALLOFWAR_9 = 13009
BUILD_HALLOFWAR_10 = 13010
BUILD_HALLOFWAR_11 = 13011
BUILD_HALLOFWAR_12 = 13012
BUILD_HALLOFWAR_13 = 13013
BUILD_HALLOFWAR_14 = 13014
BUILD_HALLOFWAR_15 = 13015
BUILD_HALLOFWAR_16 = 13016
BUILD_HALLOFWAR_17 = 13017
BUILD_HALLOFWAR_18 = 13018
BUILD_HALLOFWAR_19 = 13019
BUILD_HALLOFWAR_20 = 13020
BUILD_HALLOFWAR_21 = 13021
BUILD_HALLOFWAR_22 = 13022
BUILD_HALLOFWAR_23 = 13023
BUILD_HALLOFWAR_24 = 13024
BUILD_HALLOFWAR_25 = 13025
BUILD_HALLOFWAR_26 = 13026
BUILD_HALLOFWAR_27 = 13027
BUILD_HALLOFWAR_28 = 13028
BUILD_HALLOFWAR_29 = 13029
BUILD_HALLOFWAR_30 = 13030
BUILD_WATCHTOWER_1 = 14001
BUILD_WATCHTOWER_2 = 14002
BUILD_WATCHTOWER_3 = 14003
BUILD_WATCHTOWER_4 = 14004
BUILD_WATCHTOWER_5 = 14005
BUILD_WATCHTOWER_6 = 14006
BUILD_WATCHTOWER_7 = 14007
BUILD_WATCHTOWER_8 = 14008
BUILD_WATCHTOWER_9 = 14009
BUILD_WATCHTOWER_10 = 14010
BUILD_WATCHTOWER_11 = 14011
BUILD_WATCHTOWER_12 = 14012
BUILD_WATCHTOWER_13 = 14013
BUILD_WATCHTOWER_14 = 14014
BUILD_WATCHTOWER_15 = 14015
BUILD_WATCHTOWER_16 = 14016
BUILD_WATCHTOWER_17 = 14017
BUILD_WATCHTOWER_18 = 14018
BUILD_WATCHTOWER_19 = 14019
BUILD_WATCHTOWER_20 = 14020
BUILD_WATCHTOWER_21 = 14021
BUILD_WATCHTOWER_22 = 14022
BUILD_WATCHTOWER_23 = 14023
BUILD_WATCHTOWER_24 = 14024
BUILD_WATCHTOWER_25 = 14025
BUILD_WATCHTOWER_26 = 14026
BUILD_WATCHTOWER_27 = 14027
BUILD_WATCHTOWER_28 = 14028
BUILD_WATCHTOWER_29 = 14029
BUILD_WATCHTOWER_30 = 14030
BUILD_TUTTER_LEFT_1 = 15001
BUILD_TUTTER_LEFT_2 = 15002
BUILD_TUTTER_LEFT_3 = 15003
BUILD_TUTTER_LEFT_4 = 15004
BUILD_TUTTER_LEFT_5 = 15005
BUILD_TUTTER_LEFT_6 = 15006
BUILD_TUTTER_LEFT_7 = 15007
BUILD_TUTTER_LEFT_8 = 15008
BUILD_TUTTER_LEFT_9 = 15009
BUILD_TUTTER_LEFT_10 = 15010
BUILD_TUTTER_LEFT_11 = 15011
BUILD_TUTTER_LEFT_12 = 15012
BUILD_TUTTER_LEFT_13 = 15013
BUILD_TUTTER_LEFT_14 = 15014
BUILD_TUTTER_LEFT_15 = 15015
BUILD_TUTTER_LEFT_16 = 15016
BUILD_TUTTER_LEFT_17 = 15017
BUILD_TUTTER_LEFT_18 = 15018
BUILD_TUTTER_LEFT_19 = 15019
BUILD_TUTTER_LEFT_20 = 15020
BUILD_TUTTER_LEFT_21 = 15021
BUILD_TUTTER_LEFT_22 = 15022
BUILD_TUTTER_LEFT_23 = 15023
BUILD_TUTTER_LEFT_24 = 15024
BUILD_TUTTER_LEFT_25 = 15025
BUILD_TUTTER_LEFT_26 = 15026
BUILD_TUTTER_LEFT_27 = 15027
BUILD_TUTTER_LEFT_28 = 15028
BUILD_TUTTER_LEFT_29 = 15029
BUILD_TUTTER_LEFT_30 = 15030
BUILD_TUTTER_RIGHT_1 = 20001
BUILD_TUTTER_RIGHT_2 = 20002
BUILD_TUTTER_RIGHT_3 = 20003
BUILD_TUTTER_RIGHT_4 = 20004
BUILD_TUTTER_RIGHT_5 = 20005
BUILD_TUTTER_RIGHT_6 = 20006
BUILD_TUTTER_RIGHT_7 = 20007
BUILD_TUTTER_RIGHT_8 = 20008
BUILD_TUTTER_RIGHT_9 = 20009
BUILD_TUTTER_RIGHT_10 = 20010
BUILD_TUTTER_RIGHT_11 = 20011
BUILD_TUTTER_RIGHT_12 = 20012
BUILD_TUTTER_RIGHT_13 = 20013
BUILD_TUTTER_RIGHT_14 = 20014
BUILD_TUTTER_RIGHT_15 = 20015
BUILD_TUTTER_RIGHT_16 = 20016
BUILD_TUTTER_RIGHT_17 = 20017
BUILD_TUTTER_RIGHT_18 = 20018
BUILD_TUTTER_RIGHT_19 = 20019
BUILD_TUTTER_RIGHT_20 = 20020
BUILD_TUTTER_RIGHT_21 = 20021
BUILD_TUTTER_RIGHT_22 = 20022
BUILD_TUTTER_RIGHT_23 = 20023
BUILD_TUTTER_RIGHT_24 = 20024
BUILD_TUTTER_RIGHT_25 = 20025
BUILD_TUTTER_RIGHT_26 = 20026
BUILD_TUTTER_RIGHT_27 = 20027
BUILD_TUTTER_RIGHT_28 = 20028
BUILD_TUTTER_RIGHT_29 = 20029
BUILD_TUTTER_RIGHT_30 = 20030
BUILD_HELP_1 = 16001
BUILD_DRILLGROUNDS_1 = 17001
BUILD_DRILLGROUNDS_2 = 17002
BUILD_DRILLGROUNDS_3 = 17003
BUILD_DRILLGROUNDS_4 = 17004
BUILD_DRILLGROUNDS_5 = 17005
BUILD_DRILLGROUNDS_6 = 17006
BUILD_DRILLGROUNDS_7 = 17007
BUILD_DRILLGROUNDS_8 = 17008
BUILD_DRILLGROUNDS_9 = 17009
BUILD_DRILLGROUNDS_10 = 17010
BUILD_DRILLGROUNDS_11 = 17011
BUILD_DRILLGROUNDS_12 = 17012
BUILD_DRILLGROUNDS_13 = 17013
BUILD_DRILLGROUNDS_14 = 17014
BUILD_DRILLGROUNDS_15 = 17015
BUILD_DRILLGROUNDS_16 = 17016
BUILD_DRILLGROUNDS_17 = 17017
BUILD_DRILLGROUNDS_18 = 17018
BUILD_DRILLGROUNDS_19 = 17019
BUILD_DRILLGROUNDS_20 = 17020
BUILD_DRILLGROUNDS_21 = 17021
BUILD_DRILLGROUNDS_22 = 17022
BUILD_DRILLGROUNDS_23 = 17023
BUILD_DRILLGROUNDS_24 = 17024
BUILD_DRILLGROUNDS_25 = 17025
BUILD_DRILLGROUNDS_26 = 17026
BUILD_DRILLGROUNDS_27 = 17027
BUILD_DRILLGROUNDS_28 = 17028
BUILD_DRILLGROUNDS_29 = 17029
BUILD_DRILLGROUNDS_30 = 17030
BUILD_MILITARYTENT_1 = 18001
BUILD_MILITARYTENT_2 = 18002
BUILD_MILITARYTENT_3 = 18003
BUILD_MILITARYTENT_4 = 18004
BUILD_MILITARYTENT_5 = 18005
BUILD_MILITARYTENT_6 = 18006
BUILD_MILITARYTENT_7 = 18007
BUILD_MILITARYTENT_8 = 18008
BUILD_MILITARYTENT_9 = 18009
BUILD_MILITARYTENT_10 = 18010
BUILD_MILITARYTENT_11 = 18011
BUILD_MILITARYTENT_12 = 18012
BUILD_MILITARYTENT_13 = 18013
BUILD_MILITARYTENT_14 = 18014
BUILD_MILITARYTENT_15 = 18015
BUILD_MILITARYTENT_16 = 18016
BUILD_MILITARYTENT_17 = 18017
BUILD_MILITARYTENT_18 = 18018
BUILD_MILITARYTENT_19 = 18019
BUILD_MILITARYTENT_20 = 18020
BUILD_MILITARYTENT_21 = 18021
BUILD_MILITARYTENT_22 = 18022
BUILD_MILITARYTENT_23 = 18023
BUILD_MILITARYTENT_24 = 18024
BUILD_MILITARYTENT_25 = 18025
BUILD_MILITARYTENT_26 = 18026
BUILD_MILITARYTENT_27 = 18027
BUILD_MILITARYTENT_28 = 18028
BUILD_MILITARYTENT_29 = 18029
BUILD_MILITARYTENT_30 = 18030
BUILD_HOSPITAL_1 = 19001
BUILD_HOSPITAL_2 = 19002
BUILD_HOSPITAL_3 = 19003
BUILD_HOSPITAL_4 = 19004
BUILD_HOSPITAL_5 = 19005
BUILD_HOSPITAL_6 = 19006
BUILD_HOSPITAL_7 = 19007
BUILD_HOSPITAL_8 = 19008
BUILD_HOSPITAL_9 = 19009
BUILD_HOSPITAL_10 = 19010
BUILD_HOSPITAL_11 = 19011
BUILD_HOSPITAL_12 = 19012
BUILD_HOSPITAL_13 = 19013
BUILD_HOSPITAL_14 = 19014
BUILD_HOSPITAL_15 = 19015
BUILD_HOSPITAL_16 = 19016
BUILD_HOSPITAL_17 = 19017
BUILD_HOSPITAL_18 = 19018
BUILD_HOSPITAL_19 = 19019
BUILD_HOSPITAL_20 = 19020
BUILD_HOSPITAL_21 = 19021
BUILD_HOSPITAL_22 = 19022
BUILD_HOSPITAL_23 = 19023
BUILD_HOSPITAL_24 = 19024
BUILD_HOSPITAL_25 = 19025
BUILD_HOSPITAL_26 = 19026
BUILD_HOSPITAL_27 = 19027
BUILD_HOSPITAL_28 = 19028
BUILD_HOSPITAL_29 = 19029
BUILD_HOSPITAL_30 = 19030
BUILD_FARM_1 = 1001001
BUILD_FARM_2 = 1001002
BUILD_FARM_3 = 1001003
BUILD_FARM_4 = 1001004
BUILD_FARM_5 = 1001005
BUILD_FARM_6 = 1001006
BUILD_FARM_7 = 1001007
BUILD_FARM_8 = 1001008
BUILD_FARM_9 = 1001009
BUILD_FARM_10 = 1001010
BUILD_FARM_11 = 1001011
BUILD_FARM_12 = 1001012
BUILD_FARM_13 = 1001013
BUILD_FARM_14 = 1001014
BUILD_FARM_15 = 1001015
BUILD_FARM_16 = 1001016
BUILD_FARM_17 = 1001017
BUILD_FARM_18 = 1001018
BUILD_FARM_19 = 1001019
BUILD_FARM_20 = 1001020
BUILD_FARM_21 = 1001021
BUILD_FARM_22 = 1001022
BUILD_FARM_23 = 1001023
BUILD_FARM_24 = 1001024
BUILD_FARM_25 = 1001025
BUILD_FARM_26 = 1001026
BUILD_FARM_27 = 1001027
BUILD_FARM_28 = 1001028
BUILD_FARM_29 = 1001029
BUILD_FARM_30 = 1001030
BUILD_LOGGINGCAMP_1 = 1002001
BUILD_LOGGINGCAMP_2 = 1002002
BUILD_LOGGINGCAMP_3 = 1002003
BUILD_LOGGINGCAMP_4 = 1002004
BUILD_LOGGINGCAMP_5 = 1002005
BUILD_LOGGINGCAMP_6 = 1002006
BUILD_LOGGINGCAMP_7 = 1002007
BUILD_LOGGINGCAMP_8 = 1002008
BUILD_LOGGINGCAMP_9 = 1002009
BUILD_LOGGINGCAMP_10 = 1002010
BUILD_LOGGINGCAMP_11 = 1002011
BUILD_LOGGINGCAMP_12 = 1002012
BUILD_LOGGINGCAMP_13 = 1002013
BUILD_LOGGINGCAMP_14 = 1002014
BUILD_LOGGINGCAMP_15 = 1002015
BUILD_LOGGINGCAMP_16 = 1002016
BUILD_LOGGINGCAMP_17 = 1002017
BUILD_LOGGINGCAMP_18 = 1002018
BUILD_LOGGINGCAMP_19 = 1002019
BUILD_LOGGINGCAMP_20 = 1002020
BUILD_LOGGINGCAMP_21 = 1002021
BUILD_LOGGINGCAMP_22 = 1002022
BUILD_LOGGINGCAMP_23 = 1002023
BUILD_LOGGINGCAMP_24 = 1002024
BUILD_LOGGINGCAMP_25 = 1002025
BUILD_LOGGINGCAMP_26 = 1002026
BUILD_LOGGINGCAMP_27 = 1002027
BUILD_LOGGINGCAMP_28 = 1002028
BUILD_LOGGINGCAMP_29 = 1002029
BUILD_LOGGINGCAMP_30 = 1002030
BUILD_MINE_1 = 1003001
BUILD_MINE_2 = 1003002
BUILD_MINE_3 = 1003003
BUILD_MINE_4 = 1003004
BUILD_MINE_5 = 1003005
BUILD_MINE_6 = 1003006
BUILD_MINE_7 = 1003007
BUILD_MINE_8 = 1003008
BUILD_MINE_9 = 1003009
BUILD_MINE_10 = 1003010
BUILD_MINE_11 = 1003011
BUILD_MINE_12 = 1003012
BUILD_MINE_13 = 1003013
BUILD_MINE_14 = 1003014
BUILD_MINE_15 = 1003015
BUILD_MINE_16 = 1003016
BUILD_MINE_17 = 1003017
BUILD_MINE_18 = 1003018
BUILD_MINE_19 = 1003019
BUILD_MINE_20 = 1003020
BUILD_MINE_21 = 1003021
BUILD_MINE_22 = 1003022
BUILD_MINE_23 = 1003023
BUILD_MINE_24 = 1003024
BUILD_MINE_25 = 1003025
BUILD_MINE_26 = 1003026
BUILD_MINE_27 = 1003027
BUILD_MINE_28 = 1003028
BUILD_MINE_29 = 1003029
BUILD_MINE_30 = 1003030
BUILD_QUARRY_1 = 1004001
BUILD_QUARRY_2 = 1004002
BUILD_QUARRY_3 = 1004003
BUILD_QUARRY_4 = 1004004
BUILD_QUARRY_5 = 1004005
BUILD_QUARRY_6 = 1004006
BUILD_QUARRY_7 = 1004007
BUILD_QUARRY_8 = 1004008
BUILD_QUARRY_9 = 1004009
BUILD_QUARRY_10 = 1004010
BUILD_QUARRY_11 = 1004011
BUILD_QUARRY_12 = 1004012
BUILD_QUARRY_13 = 1004013
BUILD_QUARRY_14 = 1004014
BUILD_QUARRY_15 = 1004015
BUILD_QUARRY_16 = 1004016
BUILD_QUARRY_17 = 1004017
BUILD_QUARRY_18 = 1004018
BUILD_QUARRY_19 = 1004019
BUILD_QUARRY_20 = 1004020
BUILD_QUARRY_21 = 1004021
BUILD_QUARRY_22 = 1004022
BUILD_QUARRY_23 = 1004023
BUILD_QUARRY_24 = 1004024
BUILD_QUARRY_25 = 1004025
BUILD_QUARRY_26 = 1004026
BUILD_QUARRY_27 = 1004027
BUILD_QUARRY_28 = 1004028
BUILD_QUARRY_29 = 1004029
BUILD_QUARRY_30 = 1004030
BUILD_BARRACKS_1 = 2001001
BUILD_BARRACKS_2 = 2001002
BUILD_BARRACKS_3 = 2001003
BUILD_BARRACKS_4 = 2001004
BUILD_BARRACKS_5 = 2001005
BUILD_BARRACKS_6 = 2001006
BUILD_BARRACKS_7 = 2001007
BUILD_BARRACKS_8 = 2001008
BUILD_BARRACKS_9 = 2001009
BUILD_BARRACKS_10 = 2001010
BUILD_BARRACKS_11 = 2001011
BUILD_BARRACKS_12 = 2001012
BUILD_BARRACKS_13 = 2001013
BUILD_BARRACKS_14 = 2001014
BUILD_BARRACKS_15 = 2001015
BUILD_BARRACKS_16 = 2001016
BUILD_BARRACKS_17 = 2001017
BUILD_BARRACKS_18 = 2001018
BUILD_BARRACKS_19 = 2001019
BUILD_BARRACKS_20 = 2001020
BUILD_BARRACKS_21 = 2001021
BUILD_BARRACKS_22 = 2001022
BUILD_BARRACKS_23 = 2001023
BUILD_BARRACKS_24 = 2001024
BUILD_BARRACKS_25 = 2001025
BUILD_BARRACKS_26 = 2001026
BUILD_BARRACKS_27 = 2001027
BUILD_BARRACKS_28 = 2001028
BUILD_BARRACKS_29 = 2001029
BUILD_BARRACKS_30 = 2001030
BUILD_STABLES_1 = 2002001
BUILD_STABLES_2 = 2002002
BUILD_STABLES_3 = 2002003
BUILD_STABLES_4 = 2002004
BUILD_STABLES_5 = 2002005
BUILD_STABLES_6 = 2002006
BUILD_STABLES_7 = 2002007
BUILD_STABLES_8 = 2002008
BUILD_STABLES_9 = 2002009
BUILD_STABLES_10 = 2002010
BUILD_STABLES_11 = 2002011
BUILD_STABLES_12 = 2002012
BUILD_STABLES_13 = 2002013
BUILD_STABLES_14 = 2002014
BUILD_STABLES_15 = 2002015
BUILD_STABLES_16 = 2002016
BUILD_STABLES_17 = 2002017
BUILD_STABLES_18 = 2002018
BUILD_STABLES_19 = 2002019
BUILD_STABLES_20 = 2002020
BUILD_STABLES_21 = 2002021
BUILD_STABLES_22 = 2002022
BUILD_STABLES_23 = 2002023
BUILD_STABLES_24 = 2002024
BUILD_STABLES_25 = 2002025
BUILD_STABLES_26 = 2002026
BUILD_STABLES_27 = 2002027
BUILD_STABLES_28 = 2002028
BUILD_STABLES_29 = 2002029
BUILD_STABLES_30 = 2002030
BUILD_RANGE_1 = 2003001
BUILD_RANGE_2 = 2003002
BUILD_RANGE_3 = 2003003
BUILD_RANGE_4 = 2003004
BUILD_RANGE_5 = 2003005
BUILD_RANGE_6 = 2003006
BUILD_RANGE_7 = 2003007
BUILD_RANGE_8 = 2003008
BUILD_RANGE_9 = 2003009
BUILD_RANGE_10 = 2003010
BUILD_RANGE_11 = 2003011
BUILD_RANGE_12 = 2003012
BUILD_RANGE_13 = 2003013
BUILD_RANGE_14 = 2003014
BUILD_RANGE_15 = 2003015
BUILD_RANGE_16 = 2003016
BUILD_RANGE_17 = 2003017
BUILD_RANGE_18 = 2003018
BUILD_RANGE_19 = 2003019
BUILD_RANGE_20 = 2003020
BUILD_RANGE_21 = 2003021
BUILD_RANGE_22 = 2003022
BUILD_RANGE_23 = 2003023
BUILD_RANGE_24 = 2003024
BUILD_RANGE_25 = 2003025
BUILD_RANGE_26 = 2003026
BUILD_RANGE_27 = 2003027
BUILD_RANGE_28 = 2003028
BUILD_RANGE_29 = 2003029
BUILD_RANGE_30 = 2003030
BUILD_FACTORY_1 = 2004001
BUILD_FACTORY_2 = 2004002
BUILD_FACTORY_3 = 2004003
BUILD_FACTORY_4 = 2004004
BUILD_FACTORY_5 = 2004005
BUILD_FACTORY_6 = 2004006
BUILD_FACTORY_7 = 2004007
BUILD_FACTORY_8 = 2004008
BUILD_FACTORY_9 = 2004009
BUILD_FACTORY_10 = 2004010
BUILD_FACTORY_11 = 2004011
BUILD_FACTORY_12 = 2004012
BUILD_FACTORY_13 = 2004013
BUILD_FACTORY_14 = 2004014
BUILD_FACTORY_15 = 2004015
BUILD_FACTORY_16 = 2004016
BUILD_FACTORY_17 = 2004017
BUILD_FACTORY_18 = 2004018
BUILD_FACTORY_19 = 2004019
BUILD_FACTORY_20 = 2004020
BUILD_FACTORY_21 = 2004021
BUILD_FACTORY_22 = 2004022
BUILD_FACTORY_23 = 2004023
BUILD_FACTORY_24 = 2004024
BUILD_FACTORY_25 = 2004025
BUILD_FACTORY_26 = 2004026
BUILD_FACTORY_27 = 2004027
BUILD_FACTORY_28 = 2004028
BUILD_FACTORY_29 = 2004029
BUILD_FACTORY_30 = 2004030
BUILD_SHIPYARD_1 = 21001
BUILD_MASCOTPLAT_1 = 22001
BUILD_MANOR_1 = 23001
BUILD_MONSTER_1 = 24001
BUILD_RELIC_1 = 25001
BUILD_DIKUAI_FIELD = 26001
BUILD_DIKUAI_BUILD = 27001
BUILD_UNLOCK_FIELD1 = 28001
BUILD_UNLOCK_FIELD2 = 29001
BUILD_UNLOCK_FIELD3 = 30001
BUILD_UNLOCK_FIELD4 = 31001
BUILD_UNLOCK_FIELD5 = 32001
