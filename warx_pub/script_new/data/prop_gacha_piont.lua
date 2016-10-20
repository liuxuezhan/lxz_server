--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_gacha_piont = {

	[GACHA_PIONT_1] = { ID = GACHA_PIONT_1, Require = 50, BonusPolicy = "mutex_award", Bonus = {{"item",4003002,2,10000},{"item",2011001,1,10000}},},
	[GACHA_PIONT_2] = { ID = GACHA_PIONT_2, Require = 200, BonusPolicy = "mutex_award", Bonus = {{"item",4003002,5,10000},{"item",1001022,1,10000}},},
	[GACHA_PIONT_3] = { ID = GACHA_PIONT_3, Require = 500, BonusPolicy = "mutex_award", Bonus = {{"item",4003003,1,10000},{"item",1001022,2,10000},{"item",2012007,1,10000}},},
}
