print("WhatDidIPromise: Loading AKWDIP_Common.lua from AKWDIP")
if ExposedMembers.AKWDIP_Options ~= nil then 
	opt = ExposedMembers.AKWDIP_Options 
else
	include("AKWDIP_DefaultOptions.lua")
end

------------------------------------
---- Congig and Setup Functions ----
------------------------------------

isRiseAndFall                  = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9")
isGatheringStorm               = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68")
isBaseGame                     = (not isGatheringStorm) and (not isRiseAndFall)
isExtendedDiplomacyRibbon      = Modding.IsModActive("382a187f-c8ba-4094-a6a7-0d5315661f32")
isBetterLeaderIcon             = Modding.IsModActive("60A6CFAE-34CE-5D53-3640-15B122B9955B")
isCQUI                         = Modding.IsModActive("1d44b5e7-753e-405b-af24-5ee634ec8a01")
isQuickDeals                   = Modding.IsModActive("5aceed03-8639-4a81-8cbf-03f54d543502")
isMoreLenses                   = Modding.IsModActive("35f33319-ad93-4d6b-bf27-406fac382d06")
isHiddenStatsEvolved           = Modding.IsModActive("3e39e07c-bbd5-4bad-972c-65835867f49a")
isDiplomacyCompatibilityPatch  = Modding.IsModActive("253b50fc-7b24-409d-a75c-5f34fe6a9c23")

SupportedMods = {
	EDR   = isExtendedDiplomacyRibbon
	,BLI  = isBetterLeaderIcon
	,CQUI = isCQUI
	,QD   = isQuickDeals
	,ML   = isMoreLenses
	,HSE  = isHiddenStatsEvolved
	,DCP  = isDiplomacyCompatibilityPatch
	,NONE = true --not really, but this is only used as a fallback for conditional includes
}

--deal with variety of possible base DiplomacyActionView.lua's we can support
--Prefer isHiddenStatsEvolved, over DCP, over BLI, over EDR, over CQUI, over Firaxis implementations
AKWDIP_possiblebasefiles = {}
AKWDIP_possiblebasefiles["DiplomacyRibbon"] = { 
	{	GameCore = "XP2"
		,Mods = {
			 { Name = "HSE"  ,filename="DiplomacyRibbon_Expansion2.lua"}
			,{ Name = "DCP"  ,filename="DiplomacyRibbon_Expansion2.lua"}
			,{ Name = "BLI"  ,filename="DiplomacyRibbon_Expansion2_BLI.lua", hookee="AddLeader", hookFunction = "AKWDIP_AddLeaderBLI"}
			,{ Name = "EDR"  ,filename="EDR_DiplomacyRibbon_Expansion2.lua", hookee="RelationshipGet", hookFunction = "AKWDIP_GetExtendedTooltip"}
			,{ Name = "CQUI" ,filename="diplomacyribbon_CQUI_expansion2.lua", hookee="GetExtendedTooltip", hookFunction = "AKWDIP_GetExtendedTooltip"}
			,{ Name = "NONE" ,filename="DiplomacyRibbon_Expansion2.lua", hookee="AddLeader", hookFunction = "AKWDIP_AddLeader"}
		}	
	}
	,{	GameCore = "XP1"
		,Mods = {
			 { Name = "HSE"  ,filename="DiplomacyRibbon_Expansion1.lua"}
			,{ Name = "DCP"  ,filename="DiplomacyRibbon_Expansion1.lua"}
			,{ Name = "BLI"  ,filename="DiplomacyRibbon_Expansion1.lua", hookee="AddLeader", hookFunction = "AKWDIP_AddLeaderBLI"}
			,{ Name = "EDR"  ,filename="ExtendedDiplomacyRibbon.lua", hookee="RelationshipGet", hookFunction = "AKWDIP_GetExtendedTooltip"}
			,{ Name = "CQUI" ,filename="diplomacyribbon_CQUI_expansion1.lua", hookee="GetExtendedTooltip", hookFunction = "AKWDIP_GetExtendedTooltip"}
			,{ Name = "NONE" ,filename="DiplomacyRibbon_Expansion1.lua", hookee="AddLeader", hookFunction = "AKWDIP_AddLeader"}
		}
	}
	,{	GameCore = "BASEGAME"
		,Mods = {
			 { Name="HSE"   ,filename="DiplomacyRibbon.lua"}
			,{ Name = "DCP" ,filename="DiplomacyRibbon.lua"}
			,{ Name="BLI"   ,filename="DiplomacyRibbon_BLI.lua", hookee="AddLeader", hookFunction = "AKWDIP_AddLeaderBLI"}
			,{ Name="EDR"   ,filename="ExtendedDiplomacyRibbon.lua", hookee="RelationshipGet", hookFunction = "AKWDIP_GetExtendedTooltip"}
			,{ Name="CQUI"  ,filename="diplomacyribbon_CQUI_basegame.lua", hookee="GetExtendedTooltip", hookFunction = "AKWDIP_GetExtendedTooltip"}
			,{ Name="NONE"  ,filename="DiplomacyRibbon.lua", hookee="AddLeader", hookFunction = "AKWDIP_AddLeader"}
		}
	}
}

function isGameCoreActive(modkey)
	if modkey == "BASEGAME" then 
		return isBaseGame
	elseif modkey == "XP2" then 
		return isGatheringStorm
	elseif modkey == "XP1" then 
		return isRiseAndFall and (not isGatheringStorm)
	end
end

function isSupportedModActive(modkey)
	if modkey == "NONE" then 
		for k,v in pairs(SupportedMods) do
			if (k ~= "NONE") and (v ==true) then 
				return false
			end
		end	
		return true
	elseif SupportedMods[modkey] then 
		return SupportedMods[modkey]
	end
	return false
end



function GetBasefilename(basefiletype)
	local basefilename

	for k, v in ipairs(AKWDIP_possiblebasefiles[basefiletype]) do
		dprint("WhatDidIPromise: testing gamecore: ", v.GameCore)
		if isGameCoreActive(v.GameCore) then 
			print("WhatDidIPromise: Got gamecore: ", v.GameCore)
			for _, mod in ipairs(v.Mods) do
				dprint("WhatDidIPromise: testing modActive: ", mod.Name)
				if isSupportedModActive( mod.Name) then 
					print("WhatDidIPromise: found basefile for: ", mod.Name)
					basefilename = mod.filename
					break
				end
			end
			if basefilename == nil then 
				print("WhatDidIPromise: using default basefile")
				dshowrectable(v.Mods)
				local mods = v.Mods
				local mod = mods[#mods]			
				basefilename = mod.filename
			end	
			break
		end
	end
	return basefilename
end


function GetHookeeAndHooker(basefiletype)
	local hookee
	local hooker

	for k, v in ipairs(AKWDIP_possiblebasefiles[basefiletype]) do
		if isGameCoreActive(v.GameCore) then 
			for _,mod in ipairs(v.Mods) do
				dprint("WhatDidIPromise: testing modActive: ", mod.Name)
				if isSupportedModActive(mod.Name) then 
					if mod.hookee and mod.hookFunction then 
						print("WhatDidIPromise: found hooks for: ", mod.Name)
						hookee = mod.hookee
						hooker = mod.hookFunction
						break
					end
				end
			end
			if hookee == nil or hooker == nil then 
				print("WhatDidIPromise: using default hooks")
				local mods = v.Mods
				local mod = mods[#mods]
				hookee = mod.hookee
				hooker = mod.hookFunction
			end	
			break
		end
	end
	
	return hookee, hooker
end


------------------------------------
---- Utility Functions          ----
------------------------------------
function dprint(...)
	if not opt.DebugMode then return end
	print(unpack(arg))
end

-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table,  lbl:string, iLevel:number)
	if not opt.DebugMode then return end
	if lbl == nil then lbl = "" end
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	if level == 0 then print("####" .. lbl) end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, "", level+1); end
	end
end

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function TableMerge(t1, t2)
	for k,v in pairs(t2) do
		t1[k] = v
	end
	return t1
end


------------------------------------
---- Global Constants 		    ----
------------------------------------

m_DMZPlotsByPlayer = {}
m_DMZUnitThreshold = 2
m_DMZMaxTurnsOverThreshold = 0
m_DMZInitialGraceTurns = 3

PromiseResponses = 
{
	Accepted = 1
	,Refused = 2
	,Unknown =3
}
--AKWDIP_WarningPopup.lua
PromiseResponseStrings = {}
for k,v in pairs(PromiseResponses) do
	table.insert(PromiseResponseStrings, v, k) 
end

--AKWDIP_Main.lua
PromiseTypeNames = {}
for k,v in pairs(PromiseTypes) do
	PromiseTypeNames[k] =  k 
end

--Never?
local UnitTypePromiseTypeMap = {
	UNIT_SETTLER = "DONT_SETTLE_NEAR_ME"
	,UNIT_APOSTLE = "DONT_CONVERT_MY_CITIES"
	,UNIT_ARCHAEOLOGIST = "DONT_DIG_UP_MY_ARTIFACTS"
	,UNIT_SPY = "DONT_SPY_ON_ME"
	,UNIT_ARCHER = "KEEP_TROOPS_AWAY_FROM_ME"
}

------------------------------------
---- Promise Tracking Functions ----
------------------------------------

--AKWDIP_Main.lua
function AddPromise(requestor, requestedof, promiseType, promiseResponse)
	--is defined in AKWDIP_Main.lua
	if ExposedMembers.AKWDIP_AddPromise then 
		ExposedMembers.AKWDIP_AddPromise(requestor, requestedof, promiseType, promiseResponse)
	end
end

--AKWDIP_Main.lua
function ClearPromises(requestee, requestor, promisetype)
	--is defined in AKWDIP_Main.lua
	if ExposedMembers.AKWDIP_ClearPromises then 
		ExposedMembers.AKWDIP_ClearPromises(playerID, promiseType)
	end
end

--AKWDIP_Common.lua
--AKWDIP_Main.lua
--AKWDIP_MinimapPanel.lua
--AKWDIP_TroopsPromiseLense.lua
function GetPromisesOfType(promiseType)
	--is defined in AKWDIP_Main.lua
	if ExposedMembers.AKWDIP_GetPromisesOfType then 
		return ExposedMembers.AKWDIP_GetPromisesOfType(promiseType)
	end
	return {}
end

function GetPromisesOfTypeFromPlayerID(promiseType, fromplayerID)
	--is defined in AKWDIP_Main.lua
	if ExposedMembers.AKWDIP_GetPromisesOfTypeFromPlayerID then 
		return ExposedMembers.AKWDIP_GetPromisesOfTypeFromPlayerID(promiseType, fromplayerID)
	end
	return {}
end

--AKWDIP_Main.lua
--AKWDIP_Common.lua
function GetPromiseOfTypeFromPlayerIDToPlayerID(promiseType, fromplayerID, toplayerID)
	--is defined in AKWDIP_Main.lua
	if ExposedMembers.AKWDIP_GetPromiseOfTypeFromPlayerIDToPlayerID then 
		return ExposedMembers.AKWDIP_GetPromiseOfTypeFromPlayerIDToPlayerID(promiseType, fromplayerID, toplayerID)
	end
	print("WhatDidIPromise: ExposedMembers.AKWDIP_GetPromiseOfTypeFromPlayerIDToPlayerID was nil")
	return nil
end


--AKWDIP_DiplomacyRibbon.lua
function GetPromisesFromPlayerIDToPlayerID(fromplayerID, toplayerID)
	--is defined in AKWDIP_Main.lua
	if ExposedMembers.AKWDIP_GetPromisesFromPlayerIDToPlayerID then 
		return ExposedMembers.AKWDIP_GetPromisesFromPlayerIDToPlayerID(fromplayerID, toplayerID)
	end
	print("WhatDidIPromise: ExposedMembers.AKWDIP_GetPromisesFromPlayerIDToPlayerID was nil")
	return {}
end




--AKWDIP_WarningPopup.lua
function GetApplicablePromisesForUnit(UnitPlayerID, UnitID)
	local pPlayer = Players[UnitPlayerID]
	local pUnit = pPlayer:GetUnits():FindID(UnitID);

	if pPlayer and pUnit then 
		local uTypeName =  GameInfo.Units[pUnit:GetUnitType()].UnitType
		local promiseType = GetPromiseTypeForUnitType(uTypeName)
		if promiseType then
			--return GetPromisesOfType(promiseType)
			return GetPromisesOfTypeFromPlayerID(promiseType, UnitPlayerID)
		end
	end
	return {}
end


--AKWDIP_WarningPopup.lua
function GetApplicablePromisesForUnitAndLocation(UnitPlayerID, UnitID)
	local pPlayer = Players[UnitPlayerID]
	local pUnit = pPlayer:GetUnits():FindID(UnitID);
	local uTypeName =  GameInfo.Units[pUnit:GetUnitType()].UnitType
	local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY())
	local plotOwner = pPlot:GetOwner()

	local promiseType = GetPromiseTypeForUnitType(uTypeName)
	if not promiseType then return {} end

	--dprint("WhatDidIPromise: GetApplicablePromisesForUnitAndLocation", uTypeName, promiseType)
	
	if promiseType == "KEEP_TROOPS_AWAY_FROM_ME" then 
		--local troopPromises = GetPromisesOfType("KEEP_TROOPS_AWAY_FROM_ME")
		local troopPromises = GetPromisesOfTypeFromPlayerID("KEEP_TROOPS_AWAY_FROM_ME", UnitPlayerID)
		local troopLocalPromises = {}
		for _, promise in pairs(troopPromises) do
			for plotID, plotXY in pairs(GetDMZPlotXYsForPlayerID(promise.Requestor)) do
				if pPlot:GetIndex() == plotID 
				and plotOwner ~= UnitPlayerID --DMZ doesn't extend into territory owned by the requestee
				--does it extend into other non-neutral territory? don't know! Assume yest till proved otherwise
				then
					table.insert(troopLocalPromises, promise)
					break
				end
			end
		
			--if checkForNearbyTilesOwnedBy(promise.Requestor, pPlot, 2) then 
			--	table.insert(troopLocalPromises, promise)
			--end
		end
		return troopLocalPromises
	elseif promiseType == "DONT_SETTLE_NEAR_ME" then 
		--if settler is somewhere that can't have a city at all then 
		--promises don't matter
		local _, _, _, NoSettlePlots = Map.GetContinentPlotsWaterAvailability();	
		for _,pIndex in ipairs(NoSettlePlots) do
			if pPlot:GetIndex() == pIndex then 
				return {}
			end
		end

		--local settlerPromises = GetPromisesOfType("DONT_SETTLE_NEAR_ME")
		local settlerPromises = GetPromisesOfTypeFromPlayerID("DONT_SETTLE_NEAR_ME", UnitPlayerID)
		if #settlerPromises < 1 then return {} end

		local promisees = {}
		for _, promise in pairs(settlerPromises) do
			table.insert(promisees, promise.Requestor)
		end	
		
		local cityOwners = findNearbyCityOwners(pPlot, 8, promisees)
		
		local settlerLocalPromises = {}
		for _, promise in pairs(settlerPromises) do
			for _, cityOwner in ipairs(cityOwners) do
				if promise.Requestor == cityOwner then 
					table.insert(settlerLocalPromises, promise)
				end
			end
		end
		return settlerLocalPromises
	elseif promiseType == "DONT_CONVERT_MY_CITIES" then
		--local religionPromises = GetPromisesOfType("DONT_CONVERT_MY_CITIES")
		local religionPromises = GetPromisesOfTypeFromPlayerID("DONT_CONVERT_MY_CITIES", UnitPlayerID)
		if #religionPromises < 1 then return {} end

		local promisees = {}
		for _, promise in pairs(religionPromises) do
			table.insert(promisees, promise.Requestor)
		end	
		local cityOwners = findNearbyCityOwners(pPlot, 1, promisees)
		
		local religionLocalPromises = {}
		for _, promise in pairs(religionPromises) do
			for _, cityOwner in ipairs(cityOwners) do
				if promise.Requestor == cityOwner then 
					table.insert(religionLocalPromises, promise)
				end
			end
		end
		return religionLocalPromises	
	else
		if plotOwner and promiseType then 
			--local ret =  GetPromiseOfTypeForPlayerID(promiseType, plotOwner)
			local ret =  GetPromiseOfTypeFromPlayerIDToPlayerID(promiseType, UnitPlayerID, plotOwner)
			if ret ~= nil then
				return {ret}
			end
		end
	end
	return {}
end


--AKWDIP_MinimapPanel.lua
--AKWDIP_Common.lua
function findNearbyCityOwners(startingPlot, distance, limitOwners)
--	return {4}
	local nearOwners = {}

	local otherplayers = limitOwners
	if not otherplayers then 
		otherplayers = PlayerManager.GetAliveIDs()
	end
	
	for _, owner in pairs(otherplayers) do
		pPlayer = Players[owner]
		pCities = pPlayer:GetCities()
		for _, city in pCities:Members() do
			cityDistance = Map.GetPlotDistance(startingPlot:GetX(), startingPlot:GetY(), city:GetX(), city:GetY())
			if cityDistance <= distance then 
				table.insert(nearOwners, owner)
				break
			end
		end
	end
	
	return nearOwners
end

--AKWDIP_TroopsPromiseLense.lua
--AKWDIP_Common.lua
function checkForNearbyTilesOwnedBy(playerID, startingPlot, distance, skipPlots)
	if not skipPlots then skipPlots = {} end

	if not skipPlots[startingPlot:GetIndex()] then 
		if startingPlot:GetOwner() == playerID then 
			return true
		end
		skipPlots[startingPlot:GetIndex()] = true
	end
	if distance == 0 then 
		return false 
	end

	local adjPlots = Map.GetAdjacentPlots(startingPlot:GetX(), startingPlot:GetY())
	for _, plot in ipairs(adjPlots) do 
		if not skipPlots[plot:GetIndex()] then 
			if plot:GetOwner() == playerID then 
				return true
			end
			skipPlots[plot:GetIndex()] = true
		end
	end

	if distance > 1 then 
		for _,plot in ipairs(adjPlots) do
			if checkForNearbyTilesOwnedBy(playerID, plot, distance-1, skipPlots) then
				return true
			end
		end
	end

	return false
end

--AKWDIP_Main.lua
--AKWDIP_WarningPopup.lua
function IsDMZUnitThresholdBreached(playerID, otherplayerID)
	local pPlayer = Players[playerID]
	local pOtherPlayer = Players[otherplayerID]
	local dmzUnitCount = 0

	local borderZonePlotXYs = GetDMZPlotXYsForPlayerID(otherplayerID)
	--dshowrectable(borderZonePlotXYs)
	if pOtherPlayer then 

		local pUnits = pPlayer:GetUnits()
		if pUnits then 
			for _, unit in pUnits:Members() do
				if GetPromiseTypeForUnit(unit) == "KEEP_TROOPS_AWAY_FROM_ME" then 
					--dprint("WhatDidIPromise: checking unit", unit:GetID(), "for borderzone violation")
					for _, plotXY in pairs(borderZonePlotXYs) do
						--dprint("WhatDidIPromise: unit:GetX()", unit:GetX(), " unit:GetY() ", unit:GetY())
						--dprint("WhatDidIPromise: plotXY.x", plotXY.x, " plotXY.y ", plotXY.y)
						
						if (plotXY.x == unit:GetX()) and (plotXY.y == unit:GetY()) then 
							--dprint("WhatDidIPromise: unit", unit:GetID(), "is in borderzone of player: ", otherplayerID)
							
							
							--need to check that the unit is not on a plot it owns 
							--before incrementing the count here
							dmzUnitCount = 1 + dmzUnitCount
							
						end
					end
				end
			end
		end
	end
	
	dprint("dmzUnitCount", dmzUnitCount)

	return dmzUnitCount > m_DMZUnitThreshold
end

--AKWDIP_Common.lua
--AKWDIP_TroopsPromiseLense.lua
function GetDMZPlotXYsForPlayerID(playerID)
	local currentTurn = Game.GetCurrentGameTurn()

	if m_DMZPlotsByPlayer[playerID] then 
		if m_DMZPlotsByPlayer[playerID].TurnUpdated == currentTurn then 
			return m_DMZPlotsByPlayer[playerID].PlotXYs
		end
	end
	dprint("WhatDidIPromise: Recalculating DMZ for player", playerID)

	local borderZonePlotIDs = {}
	--local playerOwnedPlots = {}
	local pPlayer = Players[playerID]
	if pPlayer == nil then
		return borderZonePlotIDs
	end
	
	local pCities = pPlayer:GetCities()
	if pCities == nil then 
		return borderZonePlotIDs
	end
	
	for _, pCity in pCities:Members() do
		local plots:table = Map.GetCityPlots():GetPurchasedPlots( pCity );
		for _,plotidx in ipairs(plots) do
			local plot = Map.GetPlotByIndex(plotidx)
			if plot then 
				borderZonePlotIDs = TableMerge(borderZonePlotIDs, GetPlotXYsWithinRangeOfPlot(plot, 2, borderZonePlotIDs))
			end
		end
	end
	
	--Confirmed: Plots that are owned by a third player (ie: neither the requestor
	-- not the requestee do count as in teh border zone for the purposes of KEEP_YOUR_TROOPS_AWAY
	-- Which can be rvery irritating when you're invading the neighbour of someone you've
	--made that promise to!
	--
	--remove plots that would be in the DMZ but are owned by someone else
	--don't know if this is right, does being in a third civ's land adjacent to 
	--a border count as a breach? If so this shoud be uncommented...
	--at the moment plots that would be in the dmz, but are owned by the player that owns the unit
	--are special cased in GetApplicablePromisesForUnitAndLocation
	--for plotidx, plotXY in pairs(borderZonePlotIDs) do
	--	if plotidx:GetOwner() ~= -1 and plotidx:GetOwner() ~= playerID then 
	--		borderZonePlotIDs[plotidx] = nil
	--	end
	--end
	
	-- also borderZonePlotIDs should be called borderZonePlotXYs...

	--cache plots
	m_DMZPlotsByPlayer[playerID] = {}
	m_DMZPlotsByPlayer[playerID].PlotXYs = borderZonePlotIDs
	 m_DMZPlotsByPlayer[playerID].TurnUpdated = currentTurn
	return m_DMZPlotsByPlayer[playerID].PlotXYs
end

--AKWDIP_Common.lua
function GetPlotXYsWithinRangeOfPlot(startingPlot, distance, skipPlots)
	local retPlotList = {}
	if not skipPlots then skipPlots = {} end

	if distance == 0 then 
		if not skipPlots[startingPlot:GetIndex()] then 
			retPlotList[startingPlot:GetIndex()] = {x = startingPlot:GetX(), y = startingPlot:GetY()}
		end
		return retPlotList
	end

	local adjPlots = Map.GetAdjacentPlots(startingPlot:GetX(), startingPlot:GetY())
	for _, plot in ipairs(adjPlots) do 
		if not skipPlots[plot:GetIndex()] then 
			retPlotList[plot:GetIndex()] = {x = plot:GetX(), y = plot:GetY()}
			skipPlots[plot:GetIndex()] = true
		end
	end

	if distance > 1 then 
		for _,plot in ipairs(adjPlots) do
			retPlotList = TableMerge(retPlotList, GetPlotXYsWithinRangeOfPlot(plot, distance -1, skipPlots))
		end
	end
	
	return retPlotList
end

--AKWDIP_Common.lua
--AKWDIP_WarningPopup.lua
function GetPromiseTypeForUnit(pUnit)
	return GetPromiseTypeForUnitType(pUnit:GetUnitType())
end

--AKWDIP_Common.lua
--AKWDIP_WarningPopup.lua
function GetPromiseTypeForUnitType(unitType)
	if GameInfo.Units[unitType] == nil then 
		print("WARNING: GameInfo.Units[" .. tostring(unitType) .. "] is nil")
		return "NONE"
	end
	if GameInfo.Units[unitType].UnitType == "UNIT_SETTLER" then
		return "DONT_SETTLE_NEAR_ME"
	end
	if GameInfo.Units[unitType].SpreadCharges > 0 then
		return "DONT_CONVERT_MY_CITIES"
	end
	if GameInfo.Units[unitType].UnitType == "UNIT_ARCHAEOLOGIST" then
		return "DONT_DIG_UP_MY_ARTIFACTS"
	end
	if GameInfo.Units[unitType].UnitType == "UNIT_SPY" then
		return "DONT_SPY_ON_ME"
	end
	if GameInfo.Units[unitType].FormationClass == "FORMATION_CLASS_LAND_COMBAT" then 
		return "KEEP_TROOPS_AWAY_FROM_ME"
	end
	if GameInfo.Units[unitType].FormationClass == "FORMATION_CLASS_NAVAL" then 
		return "KEEP_TROOPS_AWAY_FROM_ME"
	end
	return "NONE"
end

















