print("Loading AKWDIP_DefaultOptions.lua from AKWDIP")

-- ===========================================================================
--  Default Config Options, you can edit them if you like
--      Options set from the in game window override these
--		Or they would if I had implemenetd an in-game options window!
-- ===========================================================================
local opts_defaults = {
	HighlightNoSettlePromisePlotsOnSettlerLense                         = true
	,ShowNotificationForImminentBreachOf_KEEP_TROOPS_AWAY_FROM_ME       = true
																		
	,ShowUnitPanelWarningForNearby_Accepted_DONT_SETTLE_NEAR_ME         = true
	,ShowUnitPanelWarningForNearby_Accepted_DONT_DIG_UP_MY_ARTIFACTS    = true
	,ShowUnitPanelWarningForNearby_Accepted_DONT_SPY_ON_ME              = true
	,ShowUnitPanelWarningForNearby_Accepted_KEEP_TROOPS_AWAY_FROM_ME    = true
	,ShowUnitPanelWarningForNearby_Accepted_DONT_CONVERT_MY_CITIES      = true
	
	,ShowUnitPanelWarningForNearby_Refused_DONT_SETTLE_NEAR_ME          = true
	,ShowUnitPanelWarningForNearby_Refused_DONT_DIG_UP_MY_ARTIFACTS     = true
	,ShowUnitPanelWarningForNearby_Refused_DONT_SPY_ON_ME               = true
	,ShowUnitPanelWarningForNearby_Refused_KEEP_TROOPS_AWAY_FROM_ME     = true
	,ShowUnitPanelWarningForNearby_Refused_DONT_CONVERT_MY_CITIES       = true

	,ShowUnitPanelWarningForNearby_Requested_DONT_SETTLE_NEAR_ME        = true
	,ShowUnitPanelWarningForNearby_Requested_DONT_DIG_UP_MY_ARTIFACTS   = true
	,ShowUnitPanelWarningForNearby_Requested_DONT_SPY_ON_ME             = true
	,ShowUnitPanelWarningForNearby_Requested_KEEP_TROOPS_AWAY_FROM_ME   = true
	,ShowUnitPanelWarningForNearby_Requested_DONT_CONVERT_MY_CITIES     = true

	,ShowUnitPanelWarningForAll_Accepted_DONT_SETTLE_NEAR_ME         	= false
	,ShowUnitPanelWarningForAll_Accepted_DONT_DIG_UP_MY_ARTIFACTS    	= false
	,ShowUnitPanelWarningForAll_Accepted_DONT_SPY_ON_ME              	= false
	,ShowUnitPanelWarningForAll_Accepted_KEEP_TROOPS_AWAY_FROM_ME    	= false
	,ShowUnitPanelWarningForAll_Accepted_DONT_CONVERT_MY_CITIES      	= false

	,ShowUnitPanelWarningForAll_Refused_DONT_SETTLE_NEAR_ME       		= false
	,ShowUnitPanelWarningForAll_Refused_DONT_DIG_UP_MY_ARTIFACTS        = false
	,ShowUnitPanelWarningForAll_Refused_DONT_SPY_ON_ME                  = false
	,ShowUnitPanelWarningForAll_Refused_KEEP_TROOPS_AWAY_FROM_ME        = false
	,ShowUnitPanelWarningForAll_Refused_DONT_CONVERT_MY_CITIES          = false

	,ShowUnitPanelWarningForAll_Requested_DONT_SETTLE_NEAR_ME           = false
	,ShowUnitPanelWarningForAll_Requested_DONT_DIG_UP_MY_ARTIFACTS      = false
	,ShowUnitPanelWarningForAll_Requested_DONT_SPY_ON_ME                = false
	,ShowUnitPanelWarningForAll_Requested_KEEP_TROOPS_AWAY_FROM_ME      = false
	,ShowUnitPanelWarningForAll_Requested_DONT_CONVERT_MY_CITIES        = false



	,DebugMode = false

}

-- ===========================================================================
-- ================== DONT CHANGE ANYTHING BELOW THIS LINE! ==================
-- ===========================================================================

opts_defaults['version'] = 1.7
opt = {}
for k,v in pairs(opts_defaults) do 
	opt[k] = v
end
ExposedMembers.AKWDIP_Options = opt
print("Loaded AKWDIP_DefaultOptions.lua from AKWDIP version", opts_defaults['version'])
