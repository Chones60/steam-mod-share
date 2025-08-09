-- Suk_LoyaltyTT
-- Author: Sukritact
-- DateCreated: 12/16/2022 9:10:15 PM
-- ===========================================================================

-- ===========================================================================
	include("CivilizationIcon")
	include("LoyaltySupport")
	include("InstanceManager")

	local m_Suk_Loyalty_TT = {}
	TTManager:GetTypeControlTable("Suk_Loyalty_TT", m_Suk_Loyalty_TT)

	m_Suk_LoyaltyCurrentOwner = {
		CivIconBacking	= m_Suk_Loyalty_TT.CurrentOwnerFrame,
		CivIcon			= m_Suk_Loyalty_TT.CurrentOwnerIcon,
	}
	setmetatable(m_Suk_LoyaltyCurrentOwner, {__index = CivilizationIcon})
	m_Suk_LoyaltyCurrentOwner.Controls = m_Suk_LoyaltyCurrentOwner
	m_Suk_LoyaltyCurrentOwner:Reset()

	m_Suk_LoyaltyFutureOwner = {
		CivIconBacking	= m_Suk_Loyalty_TT.FutureOwnerFrame,
		CivIcon			= m_Suk_Loyalty_TT.FutureOwnerIcon,
	}
	setmetatable(m_Suk_LoyaltyFutureOwner, {__index = CivilizationIcon})
	m_Suk_LoyaltyFutureOwner.Controls = m_Suk_LoyaltyFutureOwner
	m_Suk_LoyaltyFutureOwner:Reset()

	m_Suk_EntriesIM = InstanceManager:new("Suk_EntryInstance", "BG", m_Suk_Loyalty_TT.EntriesStack)
--===========================================================================================
--	CONSTANTS
--===========================================================================================
	-- COLORS
	local COLOR_TTTEXT						= UI.GetColorValue(0.02, 0.11,0.2,1)
	local COLOR_GREEN						= UI.GetColorValue(0, 1, 0, 1)
	local COLOR_RED							= UI.GetColorValue(1, 0, 0, 1)
	local COLOR_PRESSURE_INCREASING			= UI.GetColorValue(0, 0.75, 0, 1)
	local COLOR_PRESSURE_DECREASING			= UI.GetColorValue(0.75, 0, 0, 1)
	local COLOR_CLEAR						= UI.GetColorValueFromHexLiteral(0x00000000)
	local COLOR_WHITE						= UI.GetColorValueFromHexLiteral(0xFFFFFFAA)

	-- LOYALTY BREAKDOWN
	local PRESSURE_BREAKDOWN_TYPE_POPULATION_PRESSURE	= "PopulationPressure"
	local PRESSURE_BREAKDOWN_TYPE_GOVERNORS				= "Governors"
	local PRESSURE_BREAKDOWN_TYPE_HAPPINESS				= "Happiness"
	local PRESSURE_BREAKDOWN_TYPE_OTHER					= "Other"
	local PRESSURE_BREAKDOWN_TYPE_CITY_STATE_BONUS		= "CityStateBonus"
	local PRESSURE_BREAKDOWN_TYPE_FREE_CITY_BONUS		= "FreeCityBonus"

	local PRESSURE_CONTROLS_PAIRING = {
		PopulationPressure = {
			m_Suk_Loyalty_TT.PopulationPressureFontIcon,
			m_Suk_Loyalty_TT.PopulationPressureValue,
		},
		Governors = {
			m_Suk_Loyalty_TT.GovernorsFontIcon,
			m_Suk_Loyalty_TT.GovernorsValue,
		},
		Happiness = {
			m_Suk_Loyalty_TT.HappinessFontIcon,
			m_Suk_Loyalty_TT.HappinessValue,
		},
		Other = {
			m_Suk_Loyalty_TT.OtherFontIcon,
			m_Suk_Loyalty_TT.OtherValue,
		},
		CityStateBonus = {
			m_Suk_Loyalty_TT.CityStateBonusFontIcon,
			m_Suk_Loyalty_TT.CityStateBonusValue,
		},
		FreeCityBonus = {
			m_Suk_Loyalty_TT.FreeCityBonusFontIcon,
			m_Suk_Loyalty_TT.FreeCityBonusValue,
		},
	}

	local PRESSURE_COLLAPSIBLE = {
		CityStateBonus	= m_Suk_Loyalty_TT.CityStateBonus,
		FreeCityBonus	= m_Suk_Loyalty_TT.FreeCityBonus,
	}
--===========================================================================================
--	Utility Functions
--===========================================================================================
	-- Round number
	-----------------------------------------
		function round(num, idp)
			local mult = 10^(idp or 0)
			return math.floor(num * mult + 0.5) / mult
		end
	-----------------------------------------
	-- rPrint
	-----------------------------------------
		function rPrint(s, l, i) -- recursive Print (structure, limit, indent)
			l = (l) or 100; i = i or "";	-- default item limit, indent string
			if (l<1) then print "ERROR: Item limit reached."; return l-1 end;
			local ts = type(s);
			if (ts ~= "table") then print (i,ts,s); return l-1 end
			print (i,ts);           -- print "table"
			for k,v in pairs(s) do  -- print "[KEY] VALUE"
				l = rPrint(v, l, i.."\t["..tostring(k).."]");
				if (l < 0) then break end
			end
			return l
		end
	-----------------------------------------
	-- SetPressureBreakdownColumn
	-----------------------------------------
		function SetPressureBreakdownColumn(valueLabel:table, fontIconLabel:table, pressureValue:number, forceNegative:boolean)
			if (not forceNegative) and (pressureValue > 0) then
				valueLabel:SetText(Locale.Lookup("LOC_CULTURAL_IDENTITY_POSITIVE_PRESSURE", pressureValue));
				valueLabel:SetColor(COLOR_TTTEXT);
				fontIconLabel:SetText("[ICON_PressureUp]");
			elseif (forceNegative or pressureValue < 0) then
				valueLabel:SetText(pressureValue);
				valueLabel:SetColorByName("Red");
				fontIconLabel:SetText("[ICON_PressureDown]");
			else
				valueLabel:SetText(Locale.Lookup("LOC_CULTURAL_IDENTITY_POSITIVE_PRESSURE", pressureValue));
				valueLabel:SetColorByName("Gray");
				fontIconLabel:SetText("[ICON_Bullet]");
			end
		end
	-----------------------------------------
	-- SortPressures
	-----------------------------------------
		function SortPressures(a,b)
			return a[2] > b[2]
		end

--===========================================================================================
--	Update_Suk_CityBannerLoyaltyTT
--===========================================================================================
	local sTTCache;

	function Update_Suk_CityBannerLoyaltyTT(pCity)
		-------------------------
		-- Retrieve Data and compare against cache
		-------------------------
			local pCulturalIdentity = pCity:GetCulturalIdentity()
			local iOwner			= pCity:GetOwner()
			local iCity				= pCity:GetID()
			local iTransferPlayer	= pCulturalIdentity:GetPotentialTransferPlayer()

			local iCurrentLoyalty = pCulturalIdentity:GetLoyalty()
			local iDeltaLoyalty = pCulturalIdentity:GetLoyaltyPerTurn()

			sIdentifier = table.concat({iOwner, iCity, iTransferPlayer, iCurrentLoyalty, iDeltaLoyalty}, ".")

			if sTTCache == sIdentifier then return end
			sTTCache = sIdentifier
		-------------------------
		-- Set Civ Icons
		-------------------------
			m_Suk_LoyaltyFutureOwner:UpdateIconFromPlayerID(iTransferPlayer)
			m_Suk_LoyaltyCurrentOwner:UpdateIconFromPlayerID(iOwner)
		-------------------------
		-- Update Loyalty Percentage
		-------------------------
			local iWidth = m_Suk_Loyalty_TT.LoyaltyFillA:GetSizeX()
			local iMaxLoyalty = pCulturalIdentity:GetMaxLoyalty()

			local iLoyalPercent				= iCurrentLoyalty / iMaxLoyalty
			local iDeltaLoyaltyPercent		= iDeltaLoyalty / iMaxLoyalty
			local iNextTurnLoyaltyPercent	= math.clamp(iLoyalPercent+iDeltaLoyaltyPercent, 0, 1)

			-- Stagnant Loyalty
			if iNextTurnLoyaltyPercent == iLoyalPercent then
				m_Suk_Loyalty_TT.LoyaltyFillC:SetPercent(iLoyalPercent)
				m_Suk_Loyalty_TT.LoyaltyFillAlpha:SetHide(true)
				m_Suk_Loyalty_TT.LoyaltyFillA:SetHide(true)
			-- Increasing Loyalty
			elseif iNextTurnLoyaltyPercent > iLoyalPercent then
				m_Suk_Loyalty_TT.LoyaltyFillC:SetPercent(iLoyalPercent)

				m_Suk_Loyalty_TT.LoyaltyFillAlpha:SetHide(false)
				m_Suk_Loyalty_TT.LoyaltyFillB:SetPercent(iNextTurnLoyaltyPercent)
				m_Suk_Loyalty_TT.LoyaltyFillB:SetColor(COLOR_GREEN)

				m_Suk_Loyalty_TT.LoyaltyFillA:SetHide(false)
				m_Suk_Loyalty_TT.LoyaltyFillA:SetPercent(iNextTurnLoyaltyPercent)
				m_Suk_Loyalty_TT.LoyaltyFillA:SetColor(COLOR_PRESSURE_INCREASING)
			-- Decreasing Loyalty
			else
				m_Suk_Loyalty_TT.LoyaltyFillC:SetPercent(iNextTurnLoyaltyPercent)

				m_Suk_Loyalty_TT.LoyaltyFillAlpha:SetHide(false)
				m_Suk_Loyalty_TT.LoyaltyFillB:SetPercent(iLoyalPercent)
				m_Suk_Loyalty_TT.LoyaltyFillB:SetColor(COLOR_PRESSURE_DECREASING)

				m_Suk_Loyalty_TT.LoyaltyFillA:SetHide(false)
				m_Suk_Loyalty_TT.LoyaltyFillA:SetColor(COLOR_GREEN)
				m_Suk_Loyalty_TT.LoyaltyFillA:SetPercent(iLoyalPercent)
			end
		-------------------------
		-- Update Loyalty Arrow
		-------------------------
			if iNextTurnLoyaltyPercent == iLoyalPercent then
				m_Suk_Loyalty_TT.LoyaltyArrow:SetHide(true)
			else
				local iArrowMaxWidth = 12
				local iArrowWidth = iArrowMaxWidth
				local iArrowPercent = (iArrowWidth/iWidth)
				local iWidthWithArrow = iLoyalPercent + (iArrowPercent * (iDeltaLoyalty/math.abs(iDeltaLoyalty)))

				if iWidthWithArrow > 1 or iWidthWithArrow < 0 then
					local iNewArrowPercent = math.min(1-iLoyalPercent, iLoyalPercent)
					iArrowWidth = round(iWidth * iNewArrowPercent)
					if iArrowWidth < 6 then iArrowWidth = 0 end
				end

				m_Suk_Loyalty_TT.LoyaltyArrow:SetHide(false)
				if iNextTurnLoyaltyPercent > iLoyalPercent then
					m_Suk_Loyalty_TT.LoyaltyArrow:SetColor(COLOR_GREEN)
					m_Suk_Loyalty_TT.LoyaltyArrow:SetSizeX(iArrowWidth)
					m_Suk_Loyalty_TT.LoyaltyArrow:Rotate(0)
					m_Suk_Loyalty_TT.LoyaltyArrow:SetOffsetX(math.floor(iWidth*iLoyalPercent))
				else
					m_Suk_Loyalty_TT.LoyaltyArrow:SetColor(COLOR_RED)
					m_Suk_Loyalty_TT.LoyaltyArrow:SetSizeX(iArrowWidth)
					m_Suk_Loyalty_TT.LoyaltyArrow:Rotate(180)
					m_Suk_Loyalty_TT.LoyaltyArrow:SetOffsetX(math.floor(iWidth*iLoyalPercent)-iArrowWidth+2)
				end
			end
		-------------------------
		-- Update Text
		-------------------------
			local sFontIcon = iDeltaLoyalty >= 0 and "[ICON_PressureUp]" or "[ICON_PressureDown]"
			local sLoyalStatusTT = GetLoyaltyStatusTooltip(pCity);
			local sLoyaltyFillTT = Locale.Lookup(
				"LOC_LOYALTY_STATUS_TT",
				sFontIcon,
				round(iCurrentLoyalty,1),
				iMaxLoyalty,
				sLoyalStatusTT
			)
			local sLoyaltyPercentage = Locale.Lookup(
				"LOC_CULTURAL_IDENTITY_LOYALTY_PERCENTAGE",
				round(iCurrentLoyalty, 1),
				iMaxLoyalty,
				sFontIcon,
				round(iDeltaLoyalty, 1).." "
			)
			m_Suk_Loyalty_TT.LoyaltyPercentageLabel:SetText(sLoyaltyPercentage)
			m_Suk_Loyalty_TT.RebelliomLabel:SetText(Locale.ToUpper(sLoyalStatusTT))

			local iLoyaltyLevel = pCulturalIdentity:GetLoyaltyLevel()
			local sLoyaltyLevelName = GameInfo.LoyaltyLevels[iLoyaltyLevel].Name
			m_Suk_Loyalty_TT.StausLabel:LocalizeAndSetText(sLoyaltyLevelName)
		-------------------------
		-- Stop here in cities that are always fully loyal
		-------------------------
			local bAlwaysLoyal = pCulturalIdentity:IsAlwaysFullyLoyal()
			if bAlwaysLoyal then
				m_Suk_Loyalty_TT.LoyaltyPressure:SetHide(true)
				m_Suk_Loyalty_TT.PopulationPressureStack:SetHide(true)
				m_Suk_Loyalty_TT.RebelliomLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_CULTURAL_IDENTITY_PER_TURN_ALWAYS_LOYAL")))
				return
			end
		-------------------------
		-- Identity Sources Breakdown
		-------------------------
			m_Suk_Loyalty_TT.LoyaltyPressure:SetHide(false)
			local tIdentitySourcesRaw = pCulturalIdentity:GetIdentitySourcesBreakdown()

			-- Okay, so the output is somewhat awkwardly formatted
			-- So we reform it to make it easier to manage
			local tIdentitySources = {}
			for _, tIdentitySource in pairs(tIdentitySourcesRaw) do
				for sName, iPressure in pairs(tIdentitySource) do
					tIdentitySources[sName] = iPressure
				end
			end

			for sName,tControls in pairs(PRESSURE_CONTROLS_PAIRING) do

				tFontIconControl = PRESSURE_CONTROLS_PAIRING[sName][1]
				tValueControl = PRESSURE_CONTROLS_PAIRING[sName][2]
				if PRESSURE_COLLAPSIBLE[sName] then
					PRESSURE_COLLAPSIBLE[sName]:SetHide(false)
				end

				if tIdentitySources[sName] then
					local iPressure = round(tIdentitySources[sName], 1)
					SetPressureBreakdownColumn(tValueControl, tFontIconControl, iPressure)
				else
					if PRESSURE_COLLAPSIBLE[sName] then
						PRESSURE_COLLAPSIBLE[sName]:SetHide(true)
					else
						SetPressureBreakdownColumn(tValueControl, tFontIconControl, 0)
					end
				end
			end
		-------------------------
		-- Population Pressure Breakdown
		-------------------------
			m_Suk_Loyalty_TT.PopulationPressureStack:SetHide(false)
			local tPopulationPressureRaw = pCulturalIdentity:GetCityIdentityPressures()
			local tPopulationPressureHelper = {}
			local tPopulationPressure = {}
			local iPressureLocal = 0
			local iPressureForeign = 0

			-- Sum up the pressure from all the cities
			for _,tPressure in pairs(tPopulationPressureRaw) do
				local iPressurePlayer = tPressure.CityOwner
				local iPressure = tPressure.IdentityPressureTotal

				if iPressure ~= 0 then

					-- The Sum of foreign and domestic pressures will be needed for futher calculations
					if iPressurePlayer == iOwner then
						iPressureLocal = iPressureLocal + iPressure
					else
						iPressureForeign = iPressureForeign + iPressure
					end

					if not tPopulationPressureHelper[iPressurePlayer] then
						tPopulationPressureHelper[iPressurePlayer] = 0
					end
					tPopulationPressureHelper[iPressurePlayer] = tPopulationPressureHelper[iPressurePlayer] + iPressure
				end
			end

			-- Reformat it as a sortable array
			-- We go ahead and calculate final pressure values too
			for iPressurePlayer, iPressure in pairs(tPopulationPressureHelper) do
				iPressure = round((10 * iPressure)/(math.min(iPressureLocal, iPressureForeign)+ 0.5), 1)
				tPopulationPressure[#tPopulationPressure+1]={iPressurePlayer, iPressure}
			end
			table.sort(tPopulationPressure, SortPressures)

			-- Generate Instances
			m_Suk_EntriesIM:ResetInstances()
			local iNumEntries = #tPopulationPressure
			for i, tRow in ipairs(tPopulationPressure) do
				local tInstance = m_Suk_EntriesIM:GetInstance()

				local iPressurePlayer = tRow[1]
				local pPlayerConfig = PlayerConfigurations[iPressurePlayer]
				local sCivName = Locale.Lookup(pPlayerConfig:GetCivilizationShortDescription())
				local sCivIcon = "ICON_" .. pPlayerConfig:GetCivilizationTypeName()

				local iBackColor, iFrontColor = UI.GetPlayerColors(iPressurePlayer)
				tInstance.EntryBacking:SetColor(iBackColor)
				tInstance.EntryIcon:SetColor(iFrontColor)

				tInstance.EntryIcon:SetIcon(sCivIcon)
				tInstance.EntryName:SetText(sCivName)

				SetPressureBreakdownColumn(
					tInstance.EntryValue,
					tInstance.EntryFontIcon,
					(iOwner==iPressurePlayer) and tRow[2] or -1*tRow[2] -- It's negative pressure if it's not from the owner!
				)

				--tInstance.EntryDivider:SetHide(i == iNumEntries)
			end

			local iUncappedPopPressure = round(
				(10 * (iPressureLocal-iPressureForeign))/(math.min(iPressureLocal, iPressureForeign)+ 0.5),
				1
			)

			SetPressureBreakdownColumn(
				m_Suk_Loyalty_TT.TotalValue,
				m_Suk_Loyalty_TT.TotalFontIcon,
				iUncappedPopPressure
			)
		-------------------------
		-------------------------
	end
--===========================================================================================
--	Suk_CityBannerLoyaltyTT
--===========================================================================================
	function Suk_CityBannerLoyaltyTT(tControl, pCity)
		tControl.Button:SetToolTipType("Suk_Loyalty_TT")
		tControl.Button:ClearToolTipCallback()
		tControl.Button:SetToolTipCallback(
			function()
				Update_Suk_CityBannerLoyaltyTT(pCity)
			end
		);
	end
--===========================================================================================
--	OnInputHandler
--	For Debug Only
--===========================================================================================
	local iPlot_Cache
	function OnInputHandler(pInputStruct)

		local uiMsg	= pInputStruct:GetMessageType()

		if uiMsg == MouseEvents.MouseMove then
			local iPlot = UI.GetCursorPlotID()

			if (iPlot_Cache ~= iPlot) then
				local pCity = CityManager.GetCityAt(Map.GetPlotLocation(iPlot))
				if pCity then
					Update_Suk_CityBannerLoyaltyTT(pCity)
					iPlot_Cache = iPlot
				end
			end
		end

		return false;	-- Don't consume, let whatever is after this get crack at input.
	end
--===========================================================================================
--	Initialize/Shutdown
--===========================================================================================
	--	OnInit
	------------------------------------------------------------------------------
		function OnInit(bIsReload)
			LuaEvents.Suk_CityBannerLoyaltyTT.Add(Suk_CityBannerLoyaltyTT)
		end
	------------------------------------------------------------------------------
	--	OnShutdown
	------------------------------------------------------------------------------
		function OnShutdown()
			LuaEvents.Suk_CityBannerLoyaltyTT.Remove(Suk_CityBannerLoyaltyTT)
		end
-- ===========================================================================
-- Initialise
-- ===========================================================================
	function Initialise()
		ContextPtr:SetInitHandler(OnInit)
		ContextPtr:SetShutdown(OnShutdown)

		--ContextPtr:SetInputHandler(OnInputHandler, true) -- Debug

		ContextPtr:SetHide(false)
	end

	Initialise()
-- ===========================================================================
-- ===========================================================================