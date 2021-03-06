--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_black_market = {

	[DEF_BLACK_MARKET_ITEM_1] = { ID = DEF_BLACK_MARKET_ITEM_1, Rate = 318, Buy = {{"res",2,8800,10000}}, Pay = {{1,1,8000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_2] = { ID = DEF_BLACK_MARKET_ITEM_2, Rate = 318, Buy = {{"res",2,44000,10000}}, Pay = {{1,1,40000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_3] = { ID = DEF_BLACK_MARKET_ITEM_3, Rate = 318, Buy = {{"res",2,132000,10000}}, Pay = {{1,1,140000}}, Notice = 0, Point = 2,},
	[DEF_BLACK_MARKET_ITEM_4] = { ID = DEF_BLACK_MARKET_ITEM_4, Rate = 318, Buy = {{"res",2,440000,10000}}, Pay = {{1,1,480000}}, Notice = 0, Point = 6,},
	[DEF_BLACK_MARKET_ITEM_5] = { ID = DEF_BLACK_MARKET_ITEM_5, Rate = 100, Buy = {{"res",2,1320000,10000}}, Pay = {{1,6,2000}}, Notice = 0, Point = 200,},
	[DEF_BLACK_MARKET_ITEM_6] = { ID = DEF_BLACK_MARKET_ITEM_6, Rate = 100, Buy = {{"res",2,4400000,10000}}, Pay = {{1,6,5000}}, Notice = 0, Point = 500,},
	[DEF_BLACK_MARKET_ITEM_7] = { ID = DEF_BLACK_MARKET_ITEM_7, Rate = 318, Buy = {{"res",1,8800,10000}}, Pay = {{1,2,8000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_8] = { ID = DEF_BLACK_MARKET_ITEM_8, Rate = 318, Buy = {{"res",1,44000,10000}}, Pay = {{1,2,40000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_9] = { ID = DEF_BLACK_MARKET_ITEM_9, Rate = 318, Buy = {{"res",1,132000,10000}}, Pay = {{1,2,140000}}, Notice = 0, Point = 2,},
	[DEF_BLACK_MARKET_ITEM_10] = { ID = DEF_BLACK_MARKET_ITEM_10, Rate = 318, Buy = {{"res",1,440000,10000}}, Pay = {{1,2,480000}}, Notice = 0, Point = 6,},
	[DEF_BLACK_MARKET_ITEM_11] = { ID = DEF_BLACK_MARKET_ITEM_11, Rate = 100, Buy = {{"res",1,1320000,10000}}, Pay = {{1,6,2000}}, Notice = 0, Point = 200,},
	[DEF_BLACK_MARKET_ITEM_12] = { ID = DEF_BLACK_MARKET_ITEM_12, Rate = 100, Buy = {{"res",1,4400000,10000}}, Pay = {{1,6,5000}}, Notice = 0, Point = 500,},
	[DEF_BLACK_MARKET_ITEM_13] = { ID = DEF_BLACK_MARKET_ITEM_13, Rate = 318, Buy = {{"res",3,1760,10000}}, Pay = {{1,2,9000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_14] = { ID = DEF_BLACK_MARKET_ITEM_14, Rate = 318, Buy = {{"res",3,8800,10000}}, Pay = {{1,2,50000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_15] = { ID = DEF_BLACK_MARKET_ITEM_15, Rate = 83, Buy = {{"res",3,26400,10000}}, Pay = {{1,6,300}}, Notice = 0, Point = 30,},
	[DEF_BLACK_MARKET_ITEM_16] = { ID = DEF_BLACK_MARKET_ITEM_16, Rate = 83, Buy = {{"res",3,88000,10000}}, Pay = {{1,6,950}}, Notice = 0, Point = 95,},
	[DEF_BLACK_MARKET_ITEM_17] = { ID = DEF_BLACK_MARKET_ITEM_17, Rate = 100, Buy = {{"res",3,264000,10000}}, Pay = {{1,6,2500}}, Notice = 0, Point = 250,},
	[DEF_BLACK_MARKET_ITEM_18] = { ID = DEF_BLACK_MARKET_ITEM_18, Rate = 100, Buy = {{"res",3,880000,10000}}, Pay = {{1,6,7000}}, Notice = 0, Point = 700,},
	[DEF_BLACK_MARKET_ITEM_19] = { ID = DEF_BLACK_MARKET_ITEM_19, Rate = 318, Buy = {{"res",4,440,10000}}, Pay = {{1,2,10000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_20] = { ID = DEF_BLACK_MARKET_ITEM_20, Rate = 83, Buy = {{"res",4,2200,10000}}, Pay = {{1,6,125}}, Notice = 0, Point = 13,},
	[DEF_BLACK_MARKET_ITEM_21] = { ID = DEF_BLACK_MARKET_ITEM_21, Rate = 83, Buy = {{"res",4,6600,10000}}, Pay = {{1,6,300}}, Notice = 0, Point = 30,},
	[DEF_BLACK_MARKET_ITEM_22] = { ID = DEF_BLACK_MARKET_ITEM_22, Rate = 83, Buy = {{"res",4,22000,10000}}, Pay = {{1,6,950}}, Notice = 0, Point = 95,},
	[DEF_BLACK_MARKET_ITEM_23] = { ID = DEF_BLACK_MARKET_ITEM_23, Rate = 100, Buy = {{"res",4,66000,10000}}, Pay = {{1,6,2500}}, Notice = 0, Point = 250,},
	[DEF_BLACK_MARKET_ITEM_24] = { ID = DEF_BLACK_MARKET_ITEM_24, Rate = 100, Buy = {{"res",4,220000,10000}}, Pay = {{1,6,7000}}, Notice = 0, Point = 700,},
	[DEF_BLACK_MARKET_ITEM_25] = { ID = DEF_BLACK_MARKET_ITEM_25, Rate = 250, Buy = {{"res",8,3600,10000}}, Pay = {{1,6,5}}, Notice = 1, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_26] = { ID = DEF_BLACK_MARKET_ITEM_26, Rate = 250, Buy = {{"res",8,36000,10000}}, Pay = {{1,6,100}}, Notice = 1, Point = 10,},
	[DEF_BLACK_MARKET_ITEM_27] = { ID = DEF_BLACK_MARKET_ITEM_27, Rate = 83, Buy = {{"res",8,360000,10000}}, Pay = {{1,6,2000}}, Notice = 0, Point = 200,},
	[DEF_BLACK_MARKET_ITEM_28] = { ID = DEF_BLACK_MARKET_ITEM_28, Rate = 100, Buy = {{"res",8,3600000,10000}}, Pay = {{1,6,20000}}, Notice = 0, Point = 2000,},
	[DEF_BLACK_MARKET_ITEM_29] = { ID = DEF_BLACK_MARKET_ITEM_29, Rate = 83, Buy = {{"item",7014001,1,10000}}, Pay = {{1,6,500}}, Notice = 0, Point = 50,},
	[DEF_BLACK_MARKET_ITEM_30] = { ID = DEF_BLACK_MARKET_ITEM_30, Rate = 83, Buy = {{"item",7014002,1,10000}}, Pay = {{1,6,650}}, Notice = 0, Point = 65,},
	[DEF_BLACK_MARKET_ITEM_31] = { ID = DEF_BLACK_MARKET_ITEM_31, Rate = 250, Buy = {{"item",7015001,1,10000}}, Pay = {{1,6,40}}, Notice = 0, Point = 4,},
	[DEF_BLACK_MARKET_ITEM_32] = { ID = DEF_BLACK_MARKET_ITEM_32, Rate = 83, Buy = {{"item",7016001,1,10000}}, Pay = {{1,6,250}}, Notice = 0, Point = 25,},
	[DEF_BLACK_MARKET_ITEM_33] = { ID = DEF_BLACK_MARKET_ITEM_33, Rate = 83, Buy = {{"item",7018001,1,10000}}, Pay = {{1,6,180}}, Notice = 0, Point = 18,},
	[DEF_BLACK_MARKET_ITEM_34] = { ID = DEF_BLACK_MARKET_ITEM_34, Rate = 182, Buy = {{"item",8005001,1,10000}}, Pay = {{1,2,90000}}, Notice = 0, Point = 2,},
	[DEF_BLACK_MARKET_ITEM_35] = { ID = DEF_BLACK_MARKET_ITEM_35, Rate = 83, Buy = {{"item",8007001,1,10000}}, Pay = {{1,6,380}}, Notice = 0, Point = 38,},
	[DEF_BLACK_MARKET_ITEM_36] = { ID = DEF_BLACK_MARKET_ITEM_36, Rate = 83, Buy = {{"item",8007002,1,10000}}, Pay = {{1,6,950}}, Notice = 1, Point = 95,},
	[DEF_BLACK_MARKET_ITEM_37] = { ID = DEF_BLACK_MARKET_ITEM_37, Rate = 182, Buy = {{"item",8009001,1,10000}}, Pay = {{1,2,40000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_38] = { ID = DEF_BLACK_MARKET_ITEM_38, Rate = 182, Buy = {{"item",8009002,1,10000}}, Pay = {{1,2,40000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_39] = { ID = DEF_BLACK_MARKET_ITEM_39, Rate = 182, Buy = {{"item",8009003,1,10000}}, Pay = {{1,2,54000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_40] = { ID = DEF_BLACK_MARKET_ITEM_40, Rate = 182, Buy = {{"item",8009004,1,10000}}, Pay = {{1,2,60000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_41] = { ID = DEF_BLACK_MARKET_ITEM_41, Rate = 182, Buy = {{"item",3001001,1,10000}}, Pay = {{1,2,9000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_42] = { ID = DEF_BLACK_MARKET_ITEM_42, Rate = 182, Buy = {{"item",3001002,1,10000}}, Pay = {{1,2,90000}}, Notice = 0, Point = 2,},
	[DEF_BLACK_MARKET_ITEM_43] = { ID = DEF_BLACK_MARKET_ITEM_43, Rate = 83, Buy = {{"item",3001002,5,10000}}, Pay = {{1,6,650}}, Notice = 0, Point = 65,},
	[DEF_BLACK_MARKET_ITEM_44] = { ID = DEF_BLACK_MARKET_ITEM_44, Rate = 83, Buy = {{"item",3001003,1,10000}}, Pay = {{1,6,650}}, Notice = 0, Point = 65,},
	[DEF_BLACK_MARKET_ITEM_45] = { ID = DEF_BLACK_MARKET_ITEM_45, Rate = 182, Buy = {{"item",3002001,1,10000}}, Pay = {{1,2,9000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_46] = { ID = DEF_BLACK_MARKET_ITEM_46, Rate = 182, Buy = {{"item",3002002,1,10000}}, Pay = {{1,2,90000}}, Notice = 0, Point = 2,},
	[DEF_BLACK_MARKET_ITEM_47] = { ID = DEF_BLACK_MARKET_ITEM_47, Rate = 182, Buy = {{"item",3003001,1,10000}}, Pay = {{1,2,9000}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_48] = { ID = DEF_BLACK_MARKET_ITEM_48, Rate = 182, Buy = {{"item",3003002,1,10000}}, Pay = {{1,2,90000}}, Notice = 0, Point = 2,},
	[DEF_BLACK_MARKET_ITEM_49] = { ID = DEF_BLACK_MARKET_ITEM_49, Rate = 250, Buy = {{"item",7023002,1,10000}}, Pay = {{1,6,20}}, Notice = 1, Point = 2,},
	[DEF_BLACK_MARKET_ITEM_50] = { ID = DEF_BLACK_MARKET_ITEM_50, Rate = 250, Buy = {{"item",2011001,1,10000}}, Pay = {{1,6,20}}, Notice = 1, Point = 2,},
	[DEF_BLACK_MARKET_ITEM_51] = { ID = DEF_BLACK_MARKET_ITEM_51, Rate = 250, Buy = {{"item",2011002,1,10000}}, Pay = {{1,6,40}}, Notice = 1, Point = 4,},
	[DEF_BLACK_MARKET_ITEM_52] = { ID = DEF_BLACK_MARKET_ITEM_52, Rate = 83, Buy = {{"item",2011003,2,10000}}, Pay = {{1,6,200}}, Notice = 0, Point = 20,},
	[DEF_BLACK_MARKET_ITEM_53] = { ID = DEF_BLACK_MARKET_ITEM_53, Rate = 250, Buy = {{"item",7023005,1,10000}}, Pay = {{1,6,4}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_54] = { ID = DEF_BLACK_MARKET_ITEM_54, Rate = 250, Buy = {{"item",7023006,1,10000}}, Pay = {{1,6,8}}, Notice = 0, Point = 1,},
	[DEF_BLACK_MARKET_ITEM_55] = { ID = DEF_BLACK_MARKET_ITEM_55, Rate = 83, Buy = {{"item",7023007,1,10000}}, Pay = {{1,6,200}}, Notice = 0, Point = 20,},
	[DEF_BLACK_MARKET_ITEM_56] = { ID = DEF_BLACK_MARKET_ITEM_56, Rate = 83, Buy = {{"item",7023008,1,10000}}, Pay = {{1,6,950}}, Notice = 0, Point = 95,},
	[DEF_BLACK_MARKET_ITEM_57] = { ID = DEF_BLACK_MARKET_ITEM_57, Rate = 100, Buy = {{"item",7024001,10,10000}}, Pay = {{1,6,3000}}, Notice = 0, Point = 300,},
	[DEF_BLACK_MARKET_ITEM_58] = { ID = DEF_BLACK_MARKET_ITEM_58, Rate = 89, Buy = {{"item",7024002,1,10000}}, Pay = {{1,6,800}}, Notice = 0, Point = 80,},
}
