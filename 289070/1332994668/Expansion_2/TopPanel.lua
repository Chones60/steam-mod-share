-- Copyright 2018-2019, Firaxis Games
--
--   ###
--   ###	WARNING: Modders, this replacement file may be REMOVED in a future 
--	 ###	update as the base game's TopPanel with extensions is sufficient.
--   ###
--   
--   ###
--

-- ===========================================================================
--	HUD Top of Screen Area
-- ===========================================================================
include( "InstanceManager" );
include( "SupportFunctions" ); -- Round
include( "ToolTipHelper_PlayerYields" );


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
META_PADDING	= 100;	-- The amount of padding to give the meta area to make enough room for the (+) when there is resource overflow
FONT_MULTIPLIER	= 11;	-- The amount to multiply times the string length to approximate the width in pixels of the label control


-- ===========================================================================
-- VARIABLES
-- ===========================================================================
m_YieldButtonSingleManager	= InstanceManager:new( "YieldButton_SingleLabel", "Top", Controls.YieldStack );
m_YieldButtonDoubleManager	= InstanceManager:new( "YieldButton_DoubleLabel", "Top", Controls.YieldStack );
m_kResourceIM				= InstanceManager:new( "ResourceInstance", "Top", Controls.ResourceStack );
m_viewReportsX				= 0;	-- With of view report button
local m_OpenPediaId;


-- ===========================================================================
-- Yield handles
-- ===========================================================================
local m_ScienceYieldButton	:table = nil;
local m_CultureYieldButton	:table = nil;
local m_GoldYieldButton		:table = nil;
local m_TourismYieldButton	:table = nil;
local m_FaithYieldButton	:table = nil;


-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnCityInitialized( playerID:number, cityID:number )
	if playerID == Game.GetLocalPlayer() then
		RefreshYields();
	end	
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerChanged( playerID:number , prevLocalPlayerID:number )	
	if playerID == -1 then return; end
	local player = Players[playerID];
	local pPlayerCities	:table = player:GetCities();	
	RefreshAll();
end

-- ===========================================================================
function OnMenu()
	LuaEvents.InGame_OpenInGameOptionsMenu();
end

-- ===========================================================================
--	Takes a value and returns the string verison with +/- and rounded to
--	the tenths decimal place.
-- ===========================================================================
function FormatValuePerTurn( value:number )
	if(value == 0) then
		return Locale.ToNumber(value);
	-- lockstep
	-- Return string version rounded to integer if absolute value above 100
	elseif (math.abs(value) > 100) then
		return Locale.Lookup("{1: number +#,###;-#,###}", value);
	-- /lockstep
	else
		return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value);
	end
end

-- ===========================================================================
--	Refresh Data and View
-- ===========================================================================
function RefreshYields()
	local ePlayer		:number = Game.GetLocalPlayer();
	local localPlayer	:table= nil;
	if ePlayer ~= -1 then
		localPlayer = Players[ePlayer];
		if localPlayer == nil then
			return;
		end
	else
		return;
	end

	---- SCIENCE ----
	if GameCapabilities.HasCapability("CAPABILITY_SCIENCE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_ScienceYieldButton = m_ScienceYieldButton or m_YieldButtonSingleManager:GetInstance();
		local playerTechnology		:table	= localPlayer:GetTechs();
		local currentScienceYield	:number = playerTechnology:GetScienceYield();
		m_ScienceYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(currentScienceYield) );	

		m_ScienceYieldButton.YieldBacking:SetToolTipString( GetScienceTooltip() );
		m_ScienceYieldButton.YieldIconString:SetText("[ICON_ScienceLarge]");
		m_ScienceYieldButton.YieldButtonStack:CalculateSize();
	end	
	
	---- CULTURE----
	if GameCapabilities.HasCapability("CAPABILITY_CULTURE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_CultureYieldButton = m_CultureYieldButton or m_YieldButtonSingleManager:GetInstance();
		local playerCulture			:table	= localPlayer:GetCulture();
		local currentCultureYield	:number = playerCulture:GetCultureYield();
		m_CultureYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(currentCultureYield) );	
		m_CultureYieldButton.YieldPerTurn:SetColorByName("ResCultureLabelCS");

		m_CultureYieldButton.YieldBacking:SetToolTipString( GetCultureTooltip() );
		m_CultureYieldButton.YieldBacking:SetColor(UI.GetColorValueFromHexLiteral(0x99fe2aec));
		m_CultureYieldButton.YieldIconString:SetText("[ICON_CultureLarge]");
		m_CultureYieldButton.YieldButtonStack:CalculateSize();
	end

	---- FAITH ----
	if GameCapabilities.HasCapability("CAPABILITY_FAITH") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_FaithYieldButton = m_FaithYieldButton or m_YieldButtonDoubleManager:GetInstance();
		local playerReligion		:table	= localPlayer:GetReligion();
		local faithYield			:number = playerReligion:GetFaithYield();
		-- lockstep deleted the following
		-- local faithBalance			:number = playerReligion:GetFaithBalance();
		-- /lockstep
		-- lockstep
		local faithBalance			:number = math.floor(playerReligion:GetFaithBalance());
		-- /lockstep
		m_FaithYieldButton.YieldBalance:SetText( Locale.ToNumber(faithBalance, "#,###.#") );	
		m_FaithYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(faithYield) );
		m_FaithYieldButton.YieldBacking:SetToolTipString( GetFaithTooltip() );
		m_FaithYieldButton.YieldIconString:SetText("[ICON_FaithLarge]");
		m_FaithYieldButton.YieldButtonStack:CalculateSize();	
	end

	---- GOLD ----
	if GameCapabilities.HasCapability("CAPABILITY_GOLD") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_GoldYieldButton = m_GoldYieldButton or m_YieldButtonDoubleManager:GetInstance();
		local playerTreasury:table	= localPlayer:GetTreasury();
		local goldYield		:number = playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance();
		local goldBalance	:number = math.floor(playerTreasury:GetGoldBalance());
		m_GoldYieldButton.YieldBalance:SetText( Locale.ToNumber(goldBalance, "#,###.#") );
		m_GoldYieldButton.YieldBalance:SetColorByName("ResGoldLabelCS");	
		m_GoldYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(goldYield) );
		m_GoldYieldButton.YieldIconString:SetText("[ICON_GoldLarge]");
		m_GoldYieldButton.YieldPerTurn:SetColorByName("ResGoldLabelCS");	

		m_GoldYieldButton.YieldBacking:SetToolTipString( GetGoldTooltip() );
		m_GoldYieldButton.YieldBacking:SetColorByName("ResGoldLabelCS");
		m_GoldYieldButton.YieldButtonStack:CalculateSize();	
	end

	---- TOURISM ----
	if GameCapabilities.HasCapability("CAPABILITY_TOURISM") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_TourismYieldButton = m_TourismYieldButton or m_YieldButtonSingleManager:GetInstance();
		local tourismRate = Round(localPlayer:GetStats():GetTourism(), 1);
		local tourismRateTT:string = Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", tourismRate);
		local tourismBreakdown = localPlayer:GetStats():GetTourismToolTip();
		if(tourismBreakdown and #tourismBreakdown > 0) then
			tourismRateTT = tourismRateTT .. "[NEWLINE][NEWLINE]" .. tourismBreakdown;
		end
		
		-- lockstep deleted the following
		-- m_TourismYieldButton.YieldPerTurn:SetText( tourismRate );	
		-- /lockstep
		-- lockstep
		m_TourismYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(tourismRate) );	
		-- /lockstep
		m_TourismYieldButton.YieldBacking:SetToolTipString(tourismRateTT);
		m_TourismYieldButton.YieldPerTurn:SetColorByName("ResTourismLabelCS");
		m_TourismYieldButton.YieldBacking:SetColorByName("ResTourismLabelCS");
		m_TourismYieldButton.YieldIconString:SetText("[ICON_TourismLarge]");
		-- lockstep deleted the following
		-- if (tourismRate > 0) then
			-- m_TourismYieldButton.Top:SetHide(false);
		-- else
			-- m_TourismYieldButton.Top:SetHide(true);
		-- end
		-- /lockstep
	end

	-- lockstep
	local pPlayerCities = localPlayer:GetCities()
	
	---- HAPPINESS ----
	local iCHVeryGood, iCHGood, iCHNormal, iCHBad, iCHVeryBad = 0, 0, 0, 0, 0
	for i, pCity in pPlayerCities:Members() do
		local pCityGrowth = pCity:GetGrowth()
		local iHappinessGrowthModifier = pCityGrowth:GetHappinessGrowthModifier()
		if iHappinessGrowthModifier > 10 then
			iCHVeryGood = iCHVeryGood + 1
		elseif iHappinessGrowthModifier > 0 then
			iCHGood = iCHGood + 1
		elseif iHappinessGrowthModifier == 0 then
			iCHNormal = iCHNormal + 1
		elseif iHappinessGrowthModifier > -100 then
			iCHBad = iCHBad +1
		else
			iCHVeryBad = iCHVeryBad + 1
		end
	end
	local sCHVeryGood = iCHVeryGood
	if iCHVeryGood >= 1 then
		sCHVeryGood = "[COLOR_LIGHTBLUE]" .. sCHVeryGood .. "[ENDCOLOR]"
	end
	local sCHGood = iCHGood
	if iCHGood >= 1 then
		sCHGood = "[COLOR_GREEN]" .. sCHGood .. "[ENDCOLOR]"
	end
	local sCHNormal = iCHNormal
	if iCHNormal >= 1 then
		sCHNormal = "[COLOR_FLOAT_FAITH]" .. sCHNormal .. "[ENDCOLOR]"
	end
	local sCHBad = iCHBad
	if iCHBad >= 1 then
		sCHBad = "[COLOR_FLOAT_GOLD]" .. sCHBad .. "[ENDCOLOR]"
	end
	local sCHVeryBad = iCHVeryBad
	if iCHVeryBad >= 1 then
		sCHVeryBad = "[COLOR_RED]" .. sCHVeryBad .. "[ENDCOLOR]"
	end
	local sHappinessVariation = sCHVeryGood .. "·" .. sCHGood .. "·" .. sCHNormal .. "·" .. sCHBad .. "·" .. sCHVeryBad
	Controls.HappinessVariation:SetText(sHappinessVariation);
	local sTooltip = Locale.Lookup("LOC_HGI_HAPPINESS", iCHVeryGood, iCHGood, iCHNormal, iCHBad, iCHVeryBad);
	Controls.Happiness:SetToolTipString(sTooltip);
	Controls.HappinessStack:CalculateSize();
	Controls.HappinessStack:ReprocessAnchoring();
	
	---- GROWTH ----
	local iCGNormal, iCGBad, iCGVeryBad = 0, 0, 0
	for i, pCity in pPlayerCities:Members() do
		local pCityGrowth = pCity:GetGrowth()
		local iHousingMultiplier = pCityGrowth:GetHousingGrowthModifier()
		local iOccupied = pCity:IsOccupied()
		if iHousingMultiplier == 0 or iOccupied then
			iCGVeryBad = iCGVeryBad + 1
		elseif iHousingMultiplier < 1 then
			iCGBad = iCGBad + 1
		else
			iCGNormal = iCGNormal + 1
		end
	end
	local sCGNormal = iCGNormal
	if iCGNormal >= 1 then
		sCGNormal = "[COLOR_FLOAT_FAITH]" .. sCGNormal .. "[ENDCOLOR]"
	end
	local sCGBad = iCGBad
	if iCGBad >= 1 then
		sCGBad = "[COLOR_FLOAT_GOLD]" .. sCGBad .. "[ENDCOLOR]"
	end
	local sCGVeryBad = iCGVeryBad
	if iCGVeryBad >= 1 then
		sCGVeryBad = "[COLOR_RED]" .. sCGVeryBad .. "[ENDCOLOR]"
	end
	local sGrowthVariation = sCGNormal .. "·" .. sCGBad .. "·" .. sCGVeryBad
	Controls.GrowthVariation:SetText(sGrowthVariation);
	local sTooltip = Locale.Lookup("LOC_HGI_GROWTH", iCGNormal, iCGBad, iCGVeryBad);
	Controls.Growth:SetToolTipString(sTooltip);
	Controls.GrowthStack:CalculateSize();
	Controls.GrowthStack:ReprocessAnchoring();
	-- /lockstep

	Controls.YieldStack:CalculateSize();
	Controls.StaticInfoStack:CalculateSize();
	Controls.InfoStack:CalculateSize();

	Controls.YieldStack:RegisterSizeChanged( RefreshResources );
	Controls.StaticInfoStack:RegisterSizeChanged( RefreshResources );
end

-- ===========================================================================
--	Game Engine Event
function OnRefreshYields()
	ContextPtr:RequestRefresh();
end

-- ===========================================================================
function RefreshTrade()

	local localPlayer = Players[Game.GetLocalPlayer()];
	if (localPlayer == nil) or not GameCapabilities.HasCapability("CAPABILITY_TRADE") then
		Controls.TradeRoutes:SetHide(true);
		return;
	end

	---- ROUTES ----
	local playerTrade	:table	= localPlayer:GetTrade();
	local routesActive	:number = playerTrade:GetNumOutgoingRoutes();
	local sRoutesActive :string = "" .. routesActive;
	local routesCapacity:number = playerTrade:GetOutgoingRouteCapacity();
	if (routesCapacity > 0) then
		if (routesActive > routesCapacity) then
			sRoutesActive = "[COLOR_RED]" .. sRoutesActive .. "[ENDCOLOR]";
		elseif (routesActive < routesCapacity) then
			sRoutesActive = "[COLOR_GREEN]" .. sRoutesActive .. "[ENDCOLOR]";
		end
		Controls.TradeRoutesActive:SetText(sRoutesActive);
		Controls.TradeRoutesCapacity:SetText(routesCapacity);

		local sTooltip = Locale.Lookup("LOC_TOP_PANEL_TRADE_ROUTES_TOOLTIP_ACTIVE", routesActive);
		sTooltip = sTooltip .. "[NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_TRADE_ROUTES_TOOLTIP_CAPACITY", routesCapacity);
		sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_TRADE_ROUTES_TOOLTIP_SOURCES_HELP");
		Controls.TradeRoutes:SetToolTipString(sTooltip);
		Controls.TradeRoutes:SetHide(false);
	else
		Controls.TradeRoutes:SetHide(true);
	end

	Controls.TradeStack:CalculateSize();
end

-- lockstep
function RefreshSpies()
	local localPlayerID = Game.GetLocalPlayer();
	if (localPlayerID == -1) then
		return;
	end
	Controls.SpyIcon:SetIcon("ICON_UNIT_SPY");
	local playerDiplomacy:table = Players[Game.GetLocalPlayer()]:GetDiplomacy();
	local spyCapacity:number = playerDiplomacy:GetSpyCapacity();
	if (spyCapacity > 0) then
		local numberOfSpies:number = 0;
		local localPlayerUnits:table = Players[localPlayerID]:GetUnits();
		for i, unit in localPlayerUnits:Members() do
			local unitInfo:table = GameInfo.Units[unit:GetUnitType()];
			if unitInfo.Spy then
				numberOfSpies = numberOfSpies + 1;
			end
		end
		local players:table = Game.GetPlayers();
		for i, player in ipairs(players) do
			local playerDiplomacy:table = player:GetDiplomacy();
			local numCapturedSpies:number = playerDiplomacy:GetNumSpiesCaptured();
			for i=0,numCapturedSpies-1,1 do
				local spyInfo:table = playerDiplomacy:GetNthCapturedSpy(player:GetID(), i);
				if spyInfo and spyInfo.OwningPlayer == Game.GetLocalPlayer() then
					numberOfSpies = numberOfSpies + 1;
				end
			end
		end
		local playerDiplomacy:table = Players[Game.GetLocalPlayer()]:GetDiplomacy();
		if playerDiplomacy then
			local numSpiesOffMap:number = playerDiplomacy:GetNumSpiesOffMap();
			for i=0,numSpiesOffMap-1,1 do
				local spyOffMapInfo:table = playerDiplomacy:GetNthOffMapSpy(Game.GetLocalPlayer(), i);
				if spyOffMapInfo and spyOffMapInfo.ReturnTurn ~= -1 then
					numberOfSpies = numberOfSpies + 1;
				end
			end
		end
		local sNumberOfSpies = numberOfSpies;
		if (numberOfSpies > spyCapacity) then
			sNumberOfSpies = "[COLOR_RED]" .. numberOfSpies .. "[ENDCOLOR]";
		elseif (numberOfSpies < spyCapacity) then
			sNumberOfSpies = "[COLOR_GREEN]" .. numberOfSpies .. "[ENDCOLOR]";
		end
		Controls.NumberOfSpies:SetText(sNumberOfSpies);
		Controls.SpyCapacity:SetText(spyCapacity);
		local sTooltip = Locale.Lookup("LOC_HGI_SPIES", numberOfSpies, spyCapacity);
		Controls.Spies:SetToolTipString(sTooltip);
		Controls.Spies:SetHide(false);
	else
		Controls.Spies:SetHide(true);
	end  
	Controls.SpyStack:CalculateSize();
	Controls.SpyStack:ReprocessAnchoring();
end
-- /lockstep

-- ===========================================================================
function RefreshInfluence()
	if GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") then
		local localPlayer = Players[Game.GetLocalPlayer()];
		if (localPlayer == nil) then
			return;
		end

		local playerInfluence	:table	= localPlayer:GetInfluence();
		local influenceBalance	:number	= Round(playerInfluence:GetPointsEarned(), 1);
		local influenceRate		:number = Round(playerInfluence:GetPointsPerTurn(), 1);
		local influenceThreshold:number	= playerInfluence:GetPointsThreshold();
		local envoysPerThreshold:number = playerInfluence:GetTokensPerThreshold();
		local currentEnvoys		:number = playerInfluence:GetTokensToGive();
		
		local sTooltip = "";

		if (currentEnvoys > 0) then
			sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_ENVOYS", currentEnvoys);
			sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		end
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_THRESHOLD", envoysPerThreshold, influenceThreshold);
		sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_BALANCE", influenceBalance);
		sTooltip = sTooltip .. "[NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_RATE", influenceRate);
		sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_SOURCES_HELP");
		
		local meterRatio = influenceBalance / influenceThreshold;
		if (meterRatio < 0) then
			meterRatio = 0;
		elseif (meterRatio > 1) then
			meterRatio = 1;
		end
		Controls.EnvoysMeter:SetPercent(meterRatio);
		Controls.EnvoysNumber:SetText(tostring(currentEnvoys));
		Controls.Envoys:SetToolTipString(sTooltip);
		Controls.EnvoysStack:CalculateSize();
	else
		Controls.Envoys:SetHide(true);
	end
end

-- ===========================================================================
function RefreshTime()
	local format = UserConfiguration.GetClockFormat();
	
	local strTime;
	
	if(format == 1) then
		strTime = os.date("%H:%M");
	else
		strTime = os.date("%I:%M %p");

		-- Remove the leading zero (if any) from 12-hour clock format
		if(string.sub(strTime, 1, 1) == "0") then
			strTime = string.sub(strTime, 2);
		end
	end

	Controls.Time:SetText( strTime );
	local d = Locale.Lookup("{1_Time : datetime full}", os.time());
	Controls.Time:SetToolTipString(d);
end

-- ===========================================================================
function RefreshResources()
	if not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_RESOURCES") then
		m_kResourceIM:ResetInstances();
		return;
	end
	local localPlayerID = Game.GetLocalPlayer();
	if (localPlayerID ~= -1) then
		m_kResourceIM:ResetInstances(); 
		local pPlayerResources	=  Players[localPlayerID]:GetResources();
		local yieldStackX		= Controls.YieldStack:GetSizeX();
		local infoStackX		= Controls.StaticInfoStack:GetSizeX();
		local metaStackX		= Controls.RightContents:GetSizeX();
		local screenX, _:number = UIManager:GetScreenSizeVal();
		local maxSize = screenX - yieldStackX - infoStackX - metaStackX - m_viewReportsX - META_PADDING;
		if (maxSize < 0) then maxSize = 0; end
		local currSize = 0;
		local isOverflow = false;
		local overflowString = "";
		local plusInstance:table;
		-- lockstep
		local iLuxuryResourcesTypes = 0;
		local iLuxuryResourcesTotal = 0;
		local sLuxuryResourcesList = "";
		-- /lockstep
		for resource in GameInfo.Resources() do
			if (resource.ResourceClassType ~= nil and resource.ResourceClassType ~= "RESOURCECLASS_BONUS" and resource.ResourceClassType ~="RESOURCECLASS_LUXURY" and resource.ResourceClassType ~="RESOURCECLASS_ARTIFACT") then
				local amount = pPlayerResources:GetResourceAmount(resource.ResourceType);
				if (amount > 0) then
					local resourceText = "[ICON_"..resource.ResourceType.."] ".. amount;
					local numDigits = 3;
					if (amount >= 10) then
						numDigits = 4;
					end
					local guessinstanceWidth = math.ceil(numDigits * FONT_MULTIPLIER);
					if(currSize + guessinstanceWidth < maxSize and not isOverflow) then
						if (amount ~= 0) then
							local instance:table = m_kResourceIM:GetInstance();
							instance.ResourceText:SetText(resourceText);
							instance.ResourceText:SetToolTipString(Locale.Lookup(resource.Name).."[NEWLINE]"..Locale.Lookup("LOC_TOOLTIP_STRATEGIC_RESOURCE"));
							instanceWidth = instance.ResourceText:GetSizeX();
							currSize = currSize + instanceWidth;
						end
					else
						if (not isOverflow) then 
							overflowString = amount.. "[ICON_"..resource.ResourceType.."]".. Locale.Lookup(resource.Name);
							local instance:table = m_kResourceIM:GetInstance();
							instance.ResourceText:SetText("[ICON_Plus]");
							plusInstance = instance.ResourceText;
						else
							overflowString = overflowString .. "[NEWLINE]".. amount.. "[ICON_"..resource.ResourceType.."]".. Locale.Lookup(resource.Name);
						end
						isOverflow = true;
					end
				end
			-- lockstep
			elseif (resource.ResourceClassType == "RESOURCECLASS_LUXURY") then
				local amount = pPlayerResources:GetResourceAmount(resource.ResourceType);
				if (amount > 0) then
					iLuxuryResourcesTypes = iLuxuryResourcesTypes + 1;
					sLuxuryResourcesList = sLuxuryResourcesList .. "[NEWLINE][ICON_"..resource.ResourceType.."] " .. amount .. " " .. Locale.Lookup(resource.Name);
				end
				iLuxuryResourcesTotal = iLuxuryResourcesTotal + amount;
			-- /lockstep
			end
		end
		if (plusInstance ~= nil) then
			plusInstance:SetToolTipString(overflowString);
		end
		Controls.ResourceStack:CalculateSize();
		if(Controls.ResourceStack:GetSizeX() == 0) then
			Controls.Resources:SetHide(true);
		else
			Controls.Resources:SetHide(false);
		end
		-- lockstep
		Controls.LuxuryResourcesIcon:SetIcon("ICON_CIVILOPEDIA_RESOURCES");
		local sLuxuryResourcesText = "(" .. iLuxuryResourcesTypes .. ")" .. iLuxuryResourcesTotal;
		Controls.LuxuryResourcesTypesPlusTotal:SetText(sLuxuryResourcesText);
		local sTooltipA = Locale.Lookup("LOC_HGI_LUXURY_RESOURCES", iLuxuryResourcesTypes, iLuxuryResourcesTotal);
		Controls.LuxuryResources:SetToolTipString(sTooltipA .. "[NEWLINE]" .. sLuxuryResourcesList);
		if(iLuxuryResourcesTotal == 0) then
			Controls.LuxuryResources:SetHide(true);
		else
			Controls.LuxuryResources:SetHide(false);
		end
		-- /lockstep
	end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnRefreshResources()
	if UI.IsInGame() == false then
		return;
	end
	if not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_RESOURCES") then
		m_kResourceIM:ResetInstances();
		return;
	end
	RefreshResources();
end

-- ===========================================================================
--	Use an animation control to occasionally (not per frame!) callback for
--	an update on the current time.
-- ===========================================================================
function OnRefreshTimeTick()
	RefreshTime();
	Controls.TimeCallback:SetToBeginning();
	Controls.TimeCallback:Play();
end

-- ===========================================================================
function RefreshTurnsRemaining()

	local endTurn = Game.GetGameEndTurn();		-- This EXCLUSIVE, i.e. the turn AFTER the last playable turn.
	local turn = Game.GetCurrentGameTurn();

	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_NORMALIZED_TURN") then
		turn = (turn - GameConfiguration.GetStartTurn()) + 1; -- Keep turns starting at 1.
		if endTurn > 0 then
			endTurn = endTurn - GameConfiguration.GetStartTurn();
		end
	end

	if endTurn > 0 then
		-- We have a hard turn limit
		Controls.Turns:SetText(tostring(turn) .. "/" .. tostring(endTurn - 1));
	else
		Controls.Turns:SetText(tostring(turn));
	end

	local strDate = Calendar.MakeYearStr(turn);
	Controls.CurrentDate:SetText(strDate);
end

-- ===========================================================================
function OnWMDUpdate(owner, WMDtype)
	local eLocalPlayer = Game.GetLocalPlayer();
	if ( eLocalPlayer ~= -1 and owner == eLocalPlayer ) then
		local player = Players[owner];
		local playerWMDs = player:GetWMDs();

		for entry in GameInfo.WMDs() do
			if (entry.WeaponType == "WMD_NUCLEAR_DEVICE") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				if (count > 0) then
					Controls.NuclearDevices:SetHide(false);
					Controls.NuclearDeviceCount:SetText(count);
				else
					Controls.NuclearDevices:SetHide(true);
				end

			elseif (entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				if (count > 0) then
					Controls.ThermoNuclearDevices:SetHide(false);
					Controls.ThermoNuclearDeviceCount:SetText(count);
				else
					Controls.ThermoNuclearDevices:SetHide(true);
				end
			end
		end

		Controls.YieldStack:CalculateSize();
	end

	OnRefreshYields();	-- Don't directly refresh, call EVENT version so it's queued in the next context update.
end

-- ===========================================================================
function OnGreatPersonActivated(playerID:number)
	if ( Game.GetLocalPlayer() == playerID ) then
		OnRefreshYields();
	end
end

-- ===========================================================================
function OnGreatWorkCreated(playerID:number)
	if ( Game.GetLocalPlayer() == playerID ) then
		OnRefreshYields();
	end
end

-- ===========================================================================
function RefreshAll()
	RefreshTurnsRemaining();
	RefreshTrade();
	-- lockstep
	RefreshSpies();
	-- /lockstep
	RefreshInfluence();
	RefreshYields();
	RefreshTime();
	RefreshResources();
	OnWMDUpdate( Game.GetLocalPlayer() );
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnTurnBegin()	
	RefreshAll();
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string)
	if type == SystemUpdateUI.ScreenResize then
		-- TODO?		
	end
end

-- ===========================================================================
function OnRefresh()
	ContextPtr:ClearRequestRefresh();
	RefreshYields();
	-- lockstep
	RefreshSpies();
	-- /lockstep
end



-- ===========================================================================
--	Game Engine Event
--	Wait until the game engine is done loading before the initial refresh,
--	otherwise there is a chance the load of the LUA threads (UI & core) will 
--  clash and then we'll all have a bad time. :(
-- ===========================================================================
function OnLoadGameViewStateDone()
	RefreshAll();
end


-- ===========================================================================
function LateInitialize()	

	-- UI Callbacks	
	Controls.CivpediaButton:RegisterCallback( Mouse.eLClick, function() LuaEvents.ToggleCivilopedia(); end);
	Controls.CivpediaButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.MenuButton:RegisterCallback( Mouse.eLClick, OnMenu );
	Controls.MenuButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.TimeCallback:RegisterEndCallback( OnRefreshTimeTick );

	-- Game Events
	Events.AnarchyBegins.Add(				OnRefreshYields );
	Events.AnarchyEnds.Add(					OnRefreshYields );
	Events.BeliefAdded.Add(					OnRefreshYields );
	Events.CityInitialized.Add(				OnCityInitialized );
	Events.CityFocusChanged.Add(            OnRefreshYields );
	Events.CityWorkerChanged.Add(           OnRefreshYields );
	Events.DiplomacySessionClosed.Add(		OnRefreshYields );
	Events.FaithChanged.Add(				OnRefreshYields );
	Events.GovernmentChanged.Add(			OnRefreshYields );
	Events.GovernmentPolicyChanged.Add(		OnRefreshYields );
	Events.GovernmentPolicyObsoleted.Add(	OnRefreshYields );
	Events.GreatWorkCreated.Add(            OnGreatWorkCreated );
	Events.ImprovementAddedToMap.Add(		OnRefreshResources );
	Events.ImprovementRemovedFromMap.Add(	OnRefreshResources );
	Events.InfluenceChanged.Add(			RefreshInfluence );
	Events.LoadGameViewStateDone.Add(		OnLoadGameViewStateDone );
	Events.LocalPlayerChanged.Add(			OnLocalPlayerChanged );
	Events.PantheonFounded.Add(				OnRefreshYields );
	Events.PlayerAgeChanged.Add(			OnRefreshYields );
	Events.ResearchCompleted.Add(			OnRefreshResources );
	Events.PlayerResourceChanged.Add(		OnRefreshResources );
	Events.SystemUpdateUI.Add(				OnUpdateUI );
	Events.TradeRouteActivityChanged.Add(	RefreshTrade );
	Events.TradeRouteCapacityChanged.Add(	RefreshTrade );
	Events.TreasuryChanged.Add(				OnRefreshYields );
	Events.TurnBegin.Add(					OnTurnBegin );
	Events.UnitAddedToMap.Add(				OnRefreshYields );
	Events.UnitGreatPersonActivated.Add(    OnGreatPersonActivated );
	Events.UnitKilledInCombat.Add(			OnRefreshYields );
	Events.UnitRemovedFromMap.Add(			OnRefreshYields );
	Events.VisualStateRestored.Add(			OnTurnBegin );
	Events.WMDCountChanged.Add(				OnWMDUpdate );	
	Events.CityProductionChanged.Add(		OnRefreshResources);

	-- If no expansions function are in scope, ready to refresh and show values.
	if not XP1_LateInitialize then
		RefreshYields();
	end
end


-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
end

-- ===========================================================================
function Initialize()	
	-- UI Callbacks	
	ContextPtr:SetInitHandler( OnInit );	
	ContextPtr:SetRefreshHandler( OnRefresh );
end
Initialize();
