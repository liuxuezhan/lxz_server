--
-- $Id$
--

module( "resmng" )
prop_buildLANGKey = {

}

prop_buildKey = {
ID = 1, NumID = 2, class = 3, mode = 4, lv = 5, name = 6, cond = 7, cons = 8, dura = 9, effect = 10, speed = 11, count = 12, trainLv = 13, 
}

prop_buildData = {

	[BUILD_CASTLE_1] = {BUILD_CASTLE_1, 1, 0, 0, 1, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_2] = {BUILD_CASTLE_2, 2, 0, 0, 2, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_3] = {BUILD_CASTLE_3, 3, 0, 0, 3, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_4] = {BUILD_CASTLE_4, 4, 0, 0, 4, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_5] = {BUILD_CASTLE_5, 5, 0, 0, 5, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_6] = {BUILD_CASTLE_6, 6, 0, 0, 6, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_7] = {BUILD_CASTLE_7, 7, 0, 0, 7, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_8] = {BUILD_CASTLE_8, 8, 0, 0, 8, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_9] = {BUILD_CASTLE_9, 9, 0, 0, 9, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_CASTLE_10] = {BUILD_CASTLE_10, 10, 0, 0, 10, "主城", nil, nil, 20, nil, nil, nil, nil, },
	[BUILD_TENT_1] = {BUILD_TENT_1, 1001, 0, 1, 1, "行军帐篷", nil, {{1,1,1000},{1,2,1000}}, 20, {TrainCount=100}, nil, nil, nil, },
	[BUILD_TENT_2] = {BUILD_TENT_2, 1002, 0, 1, 2, "行军帐篷", {{2,2}}, {{1,1,1000},{1,2,1001}}, 20, {TrainCount=101}, nil, nil, nil, },
	[BUILD_TENT_3] = {BUILD_TENT_3, 1003, 0, 1, 3, "行军帐篷", {{2,3}}, {{1,1,1000},{1,2,1002}}, 20, {TrainCount=102}, nil, nil, nil, },
	[BUILD_TENT_4] = {BUILD_TENT_4, 1004, 0, 1, 4, "行军帐篷", {{2,4}}, {{1,1,1000},{1,2,1003}}, 20, {TrainCount=103}, nil, nil, nil, },
	[BUILD_TENT_5] = {BUILD_TENT_5, 1005, 0, 1, 5, "行军帐篷", {{2,5}}, {{1,1,1000},{1,2,1004}}, 20, {TrainCount=104}, nil, nil, nil, },
	[BUILD_TENT_6] = {BUILD_TENT_6, 1006, 0, 1, 6, "行军帐篷", {{2,6}}, {{1,1,1000},{1,2,1005}}, 20, {TrainCount=105}, nil, nil, nil, },
	[BUILD_TENT_7] = {BUILD_TENT_7, 1007, 0, 1, 7, "行军帐篷", {{2,7}}, {{1,1,1000},{1,2,1006}}, 20, {TrainCount=106}, nil, nil, nil, },
	[BUILD_TENT_8] = {BUILD_TENT_8, 1008, 0, 1, 8, "行军帐篷", {{2,8}}, {{1,1,1000},{1,2,1007}}, 20, {TrainCount=107}, nil, nil, nil, },
	[BUILD_TENT_9] = {BUILD_TENT_9, 1009, 0, 1, 9, "行军帐篷", {{2,9}}, {{1,1,1000},{1,2,1008}}, 20, {TrainCount=108}, nil, nil, nil, },
	[BUILD_TENT_10] = {BUILD_TENT_10, 1010, 0, 1, 10, "行军帐篷", {{2,10}}, {{1,1,1000},{1,2,1009}}, 20, {TrainCount=109}, nil, nil, nil, },
	[BUILD_FOOD_1] = {BUILD_FOOD_1, 1001001, 1, 1, 1, "农田", nil, nil, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_2] = {BUILD_FOOD_2, 1001002, 1, 1, 2, "农田", {{2,2}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_3] = {BUILD_FOOD_3, 1001003, 1, 1, 3, "农田", {{2,3}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_4] = {BUILD_FOOD_4, 1001004, 1, 1, 4, "农田", {{2,4}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_5] = {BUILD_FOOD_5, 1001005, 1, 1, 5, "农田", {{2,5}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_6] = {BUILD_FOOD_6, 1001006, 1, 1, 6, "农田", {{2,6}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_7] = {BUILD_FOOD_7, 1001007, 1, 1, 7, "农田", {{2,7}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_8] = {BUILD_FOOD_8, 1001008, 1, 1, 8, "农田", {{2,8}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_9] = {BUILD_FOOD_9, 1001009, 1, 1, 9, "农田", {{2,9}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_FOOD_10] = {BUILD_FOOD_10, 1001010, 1, 1, 10, "农田", {{2,10}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_1] = {BUILD_WOOD_1, 1002001, 1, 2, 1, "木场", nil, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_2] = {BUILD_WOOD_2, 1002002, 1, 2, 2, "木场", {{2,2}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_3] = {BUILD_WOOD_3, 1002003, 1, 2, 3, "木场", {{2,3}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_4] = {BUILD_WOOD_4, 1002004, 1, 2, 4, "木场", {{2,4}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_5] = {BUILD_WOOD_5, 1002005, 1, 2, 5, "木场", {{2,5}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_6] = {BUILD_WOOD_6, 1002006, 1, 2, 6, "木场", {{2,6}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_7] = {BUILD_WOOD_7, 1002007, 1, 2, 7, "木场", {{2,7}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_8] = {BUILD_WOOD_8, 1002008, 1, 2, 8, "木场", {{2,8}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_9] = {BUILD_WOOD_9, 1002009, 1, 2, 9, "木场", {{2,9}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_WOOD_10] = {BUILD_WOOD_10, 1002010, 1, 2, 10, "木场", {{2,10}}, {{1,1,1000},{1,2,1000}}, 20, nil, 360, 3600, nil, },
	[BUILD_BARRACKS_1] = {BUILD_BARRACKS_1, 2001001, 2, 1, 1, "兵营", nil, {{1,1,1000},{1,2,1000}}, 20, nil, nil, nil, 1, },
	[BUILD_BARRACKS_2] = {BUILD_BARRACKS_2, 2001002, 2, 1, 2, "兵营", {{2,2}}, {{1,1,1000},{1,2,1001}}, 20, nil, nil, nil, 2, },
	[BUILD_BARRACKS_3] = {BUILD_BARRACKS_3, 2001003, 2, 1, 3, "兵营", {{2,3}}, {{1,1,1000},{1,2,1002}}, 20, nil, nil, nil, 3, },
	[BUILD_BARRACKS_4] = {BUILD_BARRACKS_4, 2001004, 2, 1, 4, "兵营", {{2,4}}, {{1,1,1000},{1,2,1003}}, 20, nil, nil, nil, 4, },
	[BUILD_BARRACKS_5] = {BUILD_BARRACKS_5, 2001005, 2, 1, 5, "兵营", {{2,5}}, {{1,1,1000},{1,2,1004}}, 20, nil, nil, nil, 5, },
	[BUILD_BARRACKS_6] = {BUILD_BARRACKS_6, 2001006, 2, 1, 6, "兵营", {{2,6}}, {{1,1,1000},{1,2,1005}}, 20, nil, nil, nil, 6, },
	[BUILD_BARRACKS_7] = {BUILD_BARRACKS_7, 2001007, 2, 1, 7, "兵营", {{2,7}}, {{1,1,1000},{1,2,1006}}, 20, nil, nil, nil, 7, },
	[BUILD_BARRACKS_8] = {BUILD_BARRACKS_8, 2001008, 2, 1, 8, "兵营", {{2,8}}, {{1,1,1000},{1,2,1007}}, 20, nil, nil, nil, 8, },
	[BUILD_BARRACKS_9] = {BUILD_BARRACKS_9, 2001009, 2, 1, 9, "兵营", {{2,9}}, {{1,1,1000},{1,2,1008}}, 20, nil, nil, nil, 9, },
	[BUILD_BARRACKS_10] = {BUILD_BARRACKS_10, 2001010, 2, 1, 10, "兵营", {{2,10}}, {{1,1,1000},{1,2,1009}}, 20, nil, nil, nil, 10, },
	[BUILD_STABLES_1] = {BUILD_STABLES_1, 2002001, 2, 2, 1, "马厩", nil, {{1,1,1000},{1,2,1000}}, 20, nil, nil, nil, 1, },
	[BUILD_STABLES_2] = {BUILD_STABLES_2, 2002002, 2, 2, 2, "马厩", {{2,2}}, {{1,1,1000},{1,2,1001}}, 20, nil, nil, nil, 2, },
	[BUILD_STABLES_3] = {BUILD_STABLES_3, 2002003, 2, 2, 3, "马厩", {{2,3}}, {{1,1,1000},{1,2,1002}}, 20, nil, nil, nil, 3, },
	[BUILD_STABLES_4] = {BUILD_STABLES_4, 2002004, 2, 2, 4, "马厩", {{2,4}}, {{1,1,1000},{1,2,1003}}, 20, nil, nil, nil, 4, },
	[BUILD_STABLES_5] = {BUILD_STABLES_5, 2002005, 2, 2, 5, "马厩", {{2,5}}, {{1,1,1000},{1,2,1004}}, 20, nil, nil, nil, 5, },
	[BUILD_STABLES_6] = {BUILD_STABLES_6, 2002006, 2, 2, 6, "马厩", {{2,6}}, {{1,1,1000},{1,2,1005}}, 20, nil, nil, nil, 6, },
	[BUILD_STABLES_7] = {BUILD_STABLES_7, 2002007, 2, 2, 7, "马厩", {{2,7}}, {{1,1,1000},{1,2,1006}}, 20, nil, nil, nil, 7, },
	[BUILD_STABLES_8] = {BUILD_STABLES_8, 2002008, 2, 2, 8, "马厩", {{2,8}}, {{1,1,1000},{1,2,1007}}, 20, nil, nil, nil, 8, },
	[BUILD_STABLES_9] = {BUILD_STABLES_9, 2002009, 2, 2, 9, "马厩", {{2,9}}, {{1,1,1000},{1,2,1008}}, 20, nil, nil, nil, 9, },
	[BUILD_STABLES_10] = {BUILD_STABLES_10, 2002010, 2, 2, 10, "马厩", {{2,10}}, {{1,1,1000},{1,2,1009}}, 20, nil, nil, nil, 10, },
	[BUILD_RANGE_1] = {BUILD_RANGE_1, 2003001, 2, 3, 1, "靶场", nil, {{1,1,1000},{1,2,1000}}, 20, nil, nil, nil, 1, },
	[BUILD_RANGE_2] = {BUILD_RANGE_2, 2003002, 2, 3, 2, "靶场", {{2,2}}, {{1,1,1000},{1,2,1001}}, 20, nil, nil, nil, 2, },
	[BUILD_RANGE_3] = {BUILD_RANGE_3, 2003003, 2, 3, 3, "靶场", {{2,3}}, {{1,1,1000},{1,2,1002}}, 20, nil, nil, nil, 3, },
	[BUILD_RANGE_4] = {BUILD_RANGE_4, 2003004, 2, 3, 4, "靶场", {{2,4}}, {{1,1,1000},{1,2,1003}}, 20, nil, nil, nil, 4, },
	[BUILD_RANGE_5] = {BUILD_RANGE_5, 2003005, 2, 3, 5, "靶场", {{2,5}}, {{1,1,1000},{1,2,1004}}, 20, nil, nil, nil, 5, },
	[BUILD_RANGE_6] = {BUILD_RANGE_6, 2003006, 2, 3, 6, "靶场", {{2,6}}, {{1,1,1000},{1,2,1005}}, 20, nil, nil, nil, 6, },
	[BUILD_RANGE_7] = {BUILD_RANGE_7, 2003007, 2, 3, 7, "靶场", {{2,7}}, {{1,1,1000},{1,2,1006}}, 20, nil, nil, nil, 7, },
	[BUILD_RANGE_8] = {BUILD_RANGE_8, 2003008, 2, 3, 8, "靶场", {{2,8}}, {{1,1,1000},{1,2,1007}}, 20, nil, nil, nil, 8, },
	[BUILD_RANGE_9] = {BUILD_RANGE_9, 2003009, 2, 3, 9, "靶场", {{2,9}}, {{1,1,1000},{1,2,1008}}, 20, nil, nil, nil, 9, },
	[BUILD_RANGE_10] = {BUILD_RANGE_10, 2003010, 2, 3, 10, "靶场", {{2,10}}, {{1,1,1000},{1,2,1009}}, 20, nil, nil, nil, 10, },
	[BUILD_FACTORY_1] = {BUILD_FACTORY_1, 2004001, 2, 4, 1, "战车工坊", nil, {{1,1,1000},{1,2,1000}}, 20, nil, nil, nil, 1, },
	[BUILD_FACTORY_2] = {BUILD_FACTORY_2, 2004002, 2, 4, 2, "战车工坊", {{2,2}}, {{1,1,1000},{1,2,1001}}, 20, nil, nil, nil, 2, },
	[BUILD_FACTORY_3] = {BUILD_FACTORY_3, 2004003, 2, 4, 3, "战车工坊", {{2,3}}, {{1,1,1000},{1,2,1002}}, 20, nil, nil, nil, 3, },
	[BUILD_FACTORY_4] = {BUILD_FACTORY_4, 2004004, 2, 4, 4, "战车工坊", {{2,4}}, {{1,1,1000},{1,2,1003}}, 20, nil, nil, nil, 4, },
	[BUILD_FACTORY_5] = {BUILD_FACTORY_5, 2004005, 2, 4, 5, "战车工坊", {{2,5}}, {{1,1,1000},{1,2,1004}}, 20, nil, nil, nil, 5, },
	[BUILD_FACTORY_6] = {BUILD_FACTORY_6, 2004006, 2, 4, 6, "战车工坊", {{2,6}}, {{1,1,1000},{1,2,1005}}, 20, nil, nil, nil, 6, },
	[BUILD_FACTORY_7] = {BUILD_FACTORY_7, 2004007, 2, 4, 7, "战车工坊", {{2,7}}, {{1,1,1000},{1,2,1006}}, 20, nil, nil, nil, 7, },
	[BUILD_FACTORY_8] = {BUILD_FACTORY_8, 2004008, 2, 4, 8, "战车工坊", {{2,8}}, {{1,1,1000},{1,2,1007}}, 20, nil, nil, nil, 8, },
	[BUILD_FACTORY_9] = {BUILD_FACTORY_9, 2004009, 2, 4, 9, "战车工坊", {{2,9}}, {{1,1,1000},{1,2,1008}}, 20, nil, nil, nil, 9, },
	[BUILD_FACTORY_10] = {BUILD_FACTORY_10, 2004010, 2, 4, 10, "战车工坊", {{2,10}}, {{1,1,1000},{1,2,1009}}, 20, nil, nil, nil, 10, },
}



local prop_build_mt = {}
prop_build_mt.__index = function (_table, _key)
    local lang_idx = prop_buildLANGKey[_key]
    if lang_idx then
		local lang_str = propLanguageById(_table[lang_idx])
		local idx_ex = prop_buildKey[_key .. "ARG"]
		local lang_args = _table[idx_ex]
		if lang_args then
			if #lang_args > 0 then
				return string.format(lang_str,unpack(lang_args))
			end
		end
		return lang_str
    end
    local idx = prop_buildKey[_key]
    if not idx then
        return nil
    end
    return _table[idx]
end

function prop_buildById(_key_id)
    local id_data = prop_buildData[_key_id]
    if id_data == nil then
        return nil
    end
    if getmetatable(id_data) == nil then
        setmetatable(id_data, prop_build_mt)
    end
    return id_data
end

