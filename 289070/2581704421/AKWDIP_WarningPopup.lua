print("WhatDidIPromise: Loading AKWDIP_WarningPopup.lua")
if ExposedMembers.AKWDIP_Options ~= nil then 
	opt = ExposedMembers.AKWDIP_Options 
else
	include("AKWDIP_DefaultOptions.lua")
end
include("AKWDIP_Common.lua")

include("InstanceManager");

local warningIM = InstanceManager:new("WarningInstance", "WarningContainer",    Controls.WarningsStack)

--===========================================================================================
--	Initialize/Shutdown
--===========================================================================================
function OnInit( bIsReload)
	Events.LoadScreenClose.Add(InsertUI)

	--debug only
	InsertUI()
	
end

function InsertUI()
	if not ContextPtr:LookUpControl("/InGame/UnitPanel/UnitPanelBaseContainer") then return end

	--needs to be global as we adjust width relative to it when refreshing promises
	pUnitPanelBaseContainer	= ContextPtr:LookUpControl("/InGame/UnitPanel/UnitPanelBaseContainer")

	--insert our new panel, index 0, so that it is behind everything else
	pUnitPanelBaseContainer:AddChildAtIndex(Controls.WarningPanelGridAlpha, 0)

	--Move the actions stack ever so slightly to the left. Is defined in unitpanel.xml as:
	-- PrimaryArtStack Offset="1,-1
	-- ActionsStack Offset="2,-3"
	pActionStack = ContextPtr:LookUpControl("/InGame/UnitPanel/UnitPanelBaseContainer/ActionsStack")
	pPrimaryArtStack = ContextPtr:LookUpControl("/InGame/UnitPanel/UnitPanelBaseContainer/PrimaryArtStack")
	pPrimaryArtStack:SetOffsetX(4)
	pActionStack:SetOffsetX(5)

	
	RefreshPromiseInfo()
	
	if bIsReload then
	end
end

function RefreshPromiseInfo()
	local pSelectedUnit = UI.GetHeadSelectedUnit();
	if pSelectedUnit then 
		AKWDIP_OnUnitSelectionChanged(pSelectedUnit:GetOwner(), pSelectedUnit:GetID(), nil, nil, nil, true)
	end
end







function AKWDIP_OnUnitMoved(player, unitId, locationX, locationY, locallyvisible, statechange)
	AKWDIP_OnUnitSelectionChanged(player, unitId, locationX, locationY, nil, true, nil)
end


function AddPromiseWarningInstance(promise:table, nearby:boolean)
	local currentTurn = Game.GetCurrentGameTurn()
	local localPlayerID:number = Game.GetLocalPlayer();
	local iconPrefix = ""
	local acceptancestring = ""
	local nearbystring = ""
	if nearby then 
		nearbystring = "NEARBY_"
	end
	
	
	if promise.Response == PromiseResponses.Accepted then 
		iconPrefix = "[ICON_AKWDIP_GREEN_" 
		acceptancestring = "ACCEPTED_"
	elseif promise.Response == PromiseResponses.Refused then 
		iconPrefix = "[ICON_AKWDIP_RED_" 
		acceptancestring = "REFUSED_"
	else
		iconPrefix = "[ICON_AKWDIP_BLUE_" 
		acceptancestring = "REQUESTED_"
	end

	local warningString = Locale.Lookup(
		"LOC_AKWDIP_UNITPANELWARNING_".. nearbystring .. string.upper(PromiseResponseStrings[promise.Response]) .. "_" .. promise.PromiseType,
		"LOC_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName() .. "_NAME", 
		1+ promise.TurnEnds - currentTurn)

	if promise.PromiseType == "KEEP_TROOPS_AWAY_FROM_ME" and promise.TurnsToBreach and nearby and IsDMZUnitThresholdBreached(localPlayerID, promise.Requestor) then 
		if promise.TurnsToBreach < 0 then 
			warningString = Locale.Lookup(
				"LOC_AKWDIP_UNITPANELWARNING_".. nearbystring .. string.upper(PromiseResponseStrings[promise.Response]) .. "_KEEP_TROOPS_AWAY_FROM_ME_PAST" ,
				"LOC_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName() .. "_NAME", 
				1+ promise.TurnEnds - currentTurn)	
		elseif promise.TurnsToBreach < 1 then 
			warningString = Locale.Lookup(
				"LOC_AKWDIP_UNITPANELWARNING_".. nearbystring .. string.upper(PromiseResponseStrings[promise.Response]) .. "_KEEP_TROOPS_AWAY_FROM_ME_NOW" ,
				"LOC_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName() .. "_ADJECTIVE", 
				1+ promise.TurnEnds - currentTurn)	
		else
			warningString = Locale.Lookup(
				"LOC_AKWDIP_UNITPANELWARNING_".. nearbystring .. string.upper(PromiseResponseStrings[promise.Response]) .. "_KEEP_TROOPS_AWAY_FROM_ME_IMMINENT" ,
				"LOC_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName() .. "_ADJECTIVE", 
				1+ promise.TurnEnds - currentTurn,
				promise.TurnsToBreach)
		end
	end


		
	local instance:table = warningIM:GetInstance();
		
	instance.CivIcon:SetIcon("ICON_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName())
	local primaryColor, secondaryColor = UI.GetPlayerColors(promise.Requestor)
	instance.CivIcon:SetColor(secondaryColor)
	instance.CivIconBkg:SetColor(primaryColor)
	
	instance.PromiseTypeFontIcon:SetText(iconPrefix .. promise.PromiseType .."]" )
	instance.WarningMessage:SetText(warningString)
end


function AKWDIP_OnUnitSelectionChanged(player, unitId, locationX, locationY, locationZ, isSelected, isEditable)
	--dprint("WhatDidIPromise: UnitPanel::OnUnitSelectionChanged(): ",player,unitId,isSelected);
	if (not Controls) or (not Controls.WarningPanelGrid) or (not pUnitPanelBaseContainer) then 
		return
	else
		Controls.WarningPanelGrid:SetSizeX(pUnitPanelBaseContainer:GetSizeX()-10)
		Controls.WarningPanelGrid:SetHide(true)
		Controls.WarningsStack:DestroyAllChildren();
	end

	if (isSelected) then
		if player == Game.GetLocalPlayer() then 
			local promiseWarnings = {}
	
			local pPlayer = Players[player]
			local pUnit = pPlayer:GetUnits():FindID(unitId);
			local uTypeName =  GameInfo.Units[pUnit:GetUnitType()].UnitType
			local promiseTypeForUnit = GetPromiseTypeForUnitType(uTypeName)
			
		
			if opt["ShowUnitPanelWarningForAll_" .. promiseTypeForUnit]  
			or opt["ShowUnitPanelWarningForAll_Accepted_" .. promiseTypeForUnit]
			or opt["ShowUnitPanelWarningForAll_Refused_" .. promiseTypeForUnit]
			or opt["ShowUnitPanelWarningForAll_Requested_" .. promiseTypeForUnit] then 
				local unitPromises = GetApplicablePromisesForUnit(player, unitId)
				if unitPromises then 
					dshowrectable(unitPromises)
					for _,promise in ipairs(unitPromises) do 
						--print ("ShowUnitPanelWarningForAll_" .. PromiseResponseStrings[promise.Response] .. "_" .. promiseTypeForUnit)
						if opt["ShowUnitPanelWarningForAll_" .. PromiseResponseStrings[promise.Response] .. "_" .. promiseTypeForUnit] then
							table.insert(promiseWarnings, {promise, false})
						end
					end
				end
			elseif opt["ShowUnitPanelWarningForNearby_" .. promiseTypeForUnit] 
			or opt["ShowUnitPanelWarningForNearby_Accepted_" .. promiseTypeForUnit]
			or opt["ShowUnitPanelWarningForNearby_Refused_" .. promiseTypeForUnit]
			or opt["ShowUnitPanelWarningForNearby_Requested_" .. promiseTypeForUnit] then 
				local unitLocationPromises = GetApplicablePromisesForUnitAndLocation(player, unitId)
				if unitLocationPromises then 
					for _,promise in ipairs(unitLocationPromises) do 
						if opt["ShowUnitPanelWarningForNearby_" .. PromiseResponseStrings[promise.Response] .. "_" .. promiseTypeForUnit] then
							table.insert(promiseWarnings, {promise, true})
						end
					end
				end
			end
			
			table.sort(promiseWarnings, function (a,b) 
					local aRequestorDisplayName = Locale.Lookup("LOC_" .. PlayerConfigurations[a[1].Requestor]:GetCivilizationTypeName() .. "_NAME")
					local bRequestorDisplayName = Locale.Lookup("LOC_" .. PlayerConfigurations[b[1].Requestor]:GetCivilizationTypeName() .. "_NAME")
					return aRequestorDisplayName <  bRequestorDisplayName .. "_NAME" 
				end)

			for _,promise in ipairs(promiseWarnings) do 
					AddPromiseWarningInstance(promise[1], promise[2])
			end				


			Controls.WarningsStack:CalculateSize()	
				
			if #promiseWarnings > 0  then 
				Controls.WarningPanelGrid:SetHide(false)
				Controls.WarningPanelGridAlpha:SetToBeginning();
				Controls.WarningPanelGridSlide:SetToBeginning();
				Controls.WarningPanelGridAlpha:Play()
				Controls.WarningPanelGridSlide:Play();			
			end
		end

	else
		-- This event is raised on deselected units too; only hide if there
		-- is no selected units left.
		--if (UI.GetHeadSelectedUnit() == nil) then
		--	Controls.WarningPanelGridAlpha:SetHide(true)
		--end
		Controls.WarningPanelGridAlpha:SetToBeginning();
		Controls.WarningPanelGridSlide:SetToBeginning();
	end
end

------------------------------------------------------------------------------
--	OnShutdown
------------------------------------------------------------------------------
function OnShutdown()
	Controls.WarningPanelGridAlpha:ChangeParent(ContextPtr)
	--Controls.WarningPanelGrid:ChangeParent(ContextPtr)
	Events.LoadScreenClose.Remove(OnInit)
end
------------------------------------------------------------------------------
--	Initialize
------------------------------------------------------------------------------
function Initialize()
	ContextPtr:SetInitHandler(OnInit)
	ContextPtr:SetShutdown(OnShutdown)
	ContextPtr:SetInputHandler(OnInputHandler, true)
	--ContextPtr:SetHide(false)
	
	
	Events.UnitSelectionChanged.Add( AKWDIP_OnUnitSelectionChanged );
	Events.UnitMoved.Add (AKWDIP_OnUnitMoved);
	
	LuaEvents.AKWDIP_PromisesChanged.Add(RefreshPromiseInfo)
end
Initialize()
--=================================================================================================================
--=================================================================================================================


