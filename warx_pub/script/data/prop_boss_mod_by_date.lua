--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_boss_mod_by_date = {

	[DATE_1] = { ID = DATE_1, ["1_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["1_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["1_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["1_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["1_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["1_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["1_6"] = {{},{},{},{2051025,2052029,2053030}}, ["2_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["2_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["2_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["2_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["2_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["2_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["2_6"] = {{},{},{},{2051025,2052029,2053030}}, ["3_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["3_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["3_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["3_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["3_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["3_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["3_6"] = {{},{},{},{2051025,2052029,2053030}}, ["4_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["4_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["4_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["4_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["4_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["4_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["4_6"] = {{},{},{},{2051025,2052029,2053030}},},
	[DATE_2] = { ID = DATE_2, ["1_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["1_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["1_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["1_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["1_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["1_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["1_6"] = {{},{},{},{2051025,2052029,2053030}}, ["2_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["2_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["2_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["2_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["2_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["2_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["2_6"] = {{},{},{},{2051025,2052029,2053030}}, ["3_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["3_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["3_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["3_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["3_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["3_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["3_6"] = {{},{},{},{2051025,2052029,2053030}}, ["4_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["4_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["4_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["4_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["4_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["4_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["4_6"] = {{},{},{},{2051025,2052029,2053030}},},
	[DATE_3] = { ID = DATE_3, ["1_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["1_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["1_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["1_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["1_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["1_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["1_6"] = {{},{},{},{2051025,2052029,2053030}}, ["2_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["2_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["2_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["2_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["2_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["2_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["2_6"] = {{},{},{},{2051025,2052029,2053030}}, ["3_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["3_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["3_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["3_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["3_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["3_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["3_6"] = {{},{},{},{2051025,2052029,2053030}}, ["4_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["4_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["4_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["4_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["4_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["4_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["4_6"] = {{},{},{},{2051025,2052029,2053030}},},
	[DATE_4] = { ID = DATE_4, ["1_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["1_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["1_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["1_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["1_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["1_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["1_6"] = {{},{},{},{2051025,2052029,2053030}}, ["2_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["2_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["2_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["2_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["2_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["2_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["2_6"] = {{},{},{},{2051025,2052029,2053030}}, ["3_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["3_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["3_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["3_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["3_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["3_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["3_6"] = {{},{},{},{2051025,2052029,2053030}}, ["4_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["4_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["4_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["4_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["4_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["4_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["4_6"] = {{},{},{},{2051025,2052029,2053030}},},
	[DATE_5] = { ID = DATE_5, ["1_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["1_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["1_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["1_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["1_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["1_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["1_6"] = {{},{},{},{2051025,2052029,2053030}}, ["2_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["2_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["2_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["2_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["2_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["2_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["2_6"] = {{},{},{},{2051025,2052029,2053030}}, ["3_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["3_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["3_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["3_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["3_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["3_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["3_6"] = {{},{},{},{2051025,2052029,2053030}}, ["4_0"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["4_1"] = {{2001001,2001002,2001003,2001004,2001005},{},{},{}}, ["4_2"] = {{2001006,2001007,2001008,2001009},{2031009,2032009},{},{}}, ["4_3"] = {{2001010,2001011,2001012},{2031012,2032012},{2041015},{}}, ["4_4"] = {{2001013,2001014,2001015},{2031015,2032015},{2042018},{}}, ["4_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["4_6"] = {{},{},{},{2051025,2052029,2053030}},},
	[DATE_6] = { ID = DATE_6, ["1_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["1_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["1_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["1_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["1_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["1_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["1_6"] = {{},{},{},{2051025,2052029,2053030}}, ["2_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["2_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["2_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["2_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["2_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["2_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["2_6"] = {{},{},{},{2051025,2052029,2053030}}, ["3_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["3_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["3_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["3_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["3_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["3_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["3_6"] = {{},{},{},{2051025,2052029,2053030}}, ["4_0"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["4_1"] = {{2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["4_2"] = {{2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["4_3"] = {{2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["4_4"] = {{2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["4_5"] = {{2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["4_6"] = {{},{},{},{2051025,2052029,2053030}},},
	[DATE_7] = { ID = DATE_7, ["1_0"] = {{2001001,2001002,2001003,2001004,2001005,2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["1_1"] = {{2001001,2001002,2001003,2001004,2001005,2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["1_2"] = {{2001006,2001007,2001008,2001009,2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["1_3"] = {{2001010,2001011,2001012,2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["1_4"] = {{2001013,2001014,2001015,2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["1_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025,2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["1_6"] = {{},{},{},{2051025,2052029,2053030}}, ["2_0"] = {{2001001,2001002,2001003,2001004,2001005,2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["2_1"] = {{2001001,2001002,2001003,2001004,2001005,2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["2_2"] = {{2001006,2001007,2001008,2001009,2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["2_3"] = {{2001010,2001011,2001012,2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["2_4"] = {{2001013,2001014,2001015,2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["2_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025,2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["2_6"] = {{},{},{},{2051025,2052029,2053030}}, ["3_0"] = {{2001001,2001002,2001003,2001004,2001005,2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["3_1"] = {{2001001,2001002,2001003,2001004,2001005,2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["3_2"] = {{2001006,2001007,2001008,2001009,2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["3_3"] = {{2001010,2001011,2001012,2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["3_4"] = {{2001013,2001014,2001015,2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["3_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025,2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["3_6"] = {{},{},{},{2051025,2052029,2053030}}, ["4_0"] = {{2001001,2001002,2001003,2001004,2001005,2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["4_1"] = {{2001001,2001002,2001003,2001004,2001005,2002001,2002002,2002003,2002004,2002005},{},{},{}}, ["4_2"] = {{2001006,2001007,2001008,2001009,2002006,2002007,2002008,2002009},{2031009,2032009},{},{}}, ["4_3"] = {{2001010,2001011,2001012,2002010,2002011,2002012},{2031012,2032012},{2041015},{}}, ["4_4"] = {{2001013,2001014,2001015,2002013,2002014,2002015},{2031015,2032015},{2042018},{}}, ["4_5"] = {{2001016,2001017,2001018,2001019,2001020,2001021,2001022,2001023,2001024,2001025,2004025,2007025,2010025,2013025,2016025,2002016,2002017,2002018,2002019,2002020,2002021,2002022,2002023,2002024,2002025,2005025,2008025,2011025,2014025,2017025},{2031018,2032018,2031021,2032021,2031025,2032025,2033025,2034025},{2043021,2044025,2045029},{}}, ["4_6"] = {{},{},{},{2051025,2052029,2053030}},},
}
