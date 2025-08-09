print("WhatDidIPromise: Loading AKWDIP_Main.lua")
if ExposedMembers.AKWDIP_Options ~= nil then 
	opt = ExposedMembers.AKWDIP_Options 
else
	include("AKWDIP_DefaultOptions.lua")
end

include("Serialize.lua")
include("AKWDIP_Common.lua")

local AKWDIP_IMMINENT_DMZ_BREACH_NOTIFICATIONHASH = GameInfo.Types["NOTIFICATION_AKWDIP_IMMINENT_DMZ_BREACH"].Hash


function ToggleOptionsPopup()
	print("WhatDidIPromise: the button was pressed")
end

function AttachLaunchButton()
	if thereIsAnOptionsPanel and not buttonAdded then
		local topBarButtonStack = ContextPtr:LookUpControl("/InGame/TopPanel/RightContents");
		if topBarButtonStack then
			Controls.AKWDIP_TopBarButton:ChangeParent(topBarButtonStack);
			topBarButtonStack:AddChildAtIndex(Controls.AKWDIP_TopBarButton, 3);
			Controls.AKWDIP_TopBarButton:RegisterCallback(Mouse.eLClick, ToggleOptionsPopup);
			topBarButtonStack:CalculateSize();
			topBarButtonStack:ReprocessAnchoring();
			buttonAdded = true
		end
	end
end

function OnLoadGameViewStateDone()
    AttachLaunchButton();
end



function OnDiplomacyStatement(fromPlayer : number, toPlayer : number, kVariants : table)
	dprint("")
	dprint("WhatDidIPromise: #######################################################")
	dprint("WhatDidIPromise: AKWDIP_Main.lua:OnDiplomacyStatement: ")
	dprint("WhatDidIPromise: fromPlayer: ", fromPlayer)
	dprint("WhatDidIPromise: toPlayer: ", toPlayer)
	dshowrectable(kVariants, "WhatDidIPromise: kVariants")
	local statementTypeName = DiplomacyManager.GetKeyName( kVariants.StatementType );
	local statementSubTypeName = DiplomacyManager.GetKeyName( kVariants.StatementSubType );
		
	if kVariants.Initiator ~= fromPlayer 
	and kVariants.Initiator == toPlayer then 
		toPlayer = fromPlayer
		fromPlayer = kVariants.Initiator
	end
		
		
--	if 1==1 or kVariants.Initiator ~= Game.GetLocalPlayer() then 
		if WarningStatements[statementTypeName] then
			if statementSubTypeName == "NONE" then
				dprint("\tWhatDidIPromise: OnPromiseRequested ",kVariants.Initiator,toPlayer,statementTypeName )
				AddPromise( fromPlayer, toPlayer, WarningPromiseMap[statementTypeName], PromiseResponses.Requested)			
			elseif statementSubTypeName == "NEGATIVE" then
				dprint("\tWhatDidIPromise: OnPromiseRefused ",kVariants.Initiator,toPlayer,statementTypeName )
				AddPromise( fromPlayer, toPlayer, WarningPromiseMap[statementTypeName], PromiseResponses.Refused)			
			elseif statementSubTypeName == "POSITIVE" then
				dprint("\tWhatDidIPromise: OnPromiseAccepted ",kVariants.Initiator,toPlayer,statementTypeName )
				AddPromise( fromPlayer, toPlayer, WarningPromiseMap[statementTypeName], PromiseResponses.Accepted)
			else
				dprint("\tWhatDidIPromise: OnDiplomacyStatement, unexpected statementTypeName:", statementTypeName )			
			end
		end
--	else
--		dprint("\tWhatDidIPromise: OnDiplomacyStatement, ignoring promise where localplayer is the initiator" )
--	end

	dprint("WhatDidIPromise: #######################################################")
	dprint("")
end



WarningStatements = {
	WARNING_DONT_SETTLE_NEAR_ME				=1
	,WARNING_STOP_CONVERTING_MY_CITIES		=2
	,WARNING_STOP_DIGGING_UP_ARTIFACTS		=3
	,WARNING_STOP_SPYING_ON_ME				=4
	,WARNING_TOO_MANY_TROOPS_NEAR_ME		=5
}


----TODO: change this to not bother with TurnEnabled?
---- and init differently?
----ala:
--local m_Promises = {
--	-1 = {}
--}
----then just save m_Promises?

m_AKWDIP_Data = {
	TurnModEnabled = 999999
	,Promises = {dummy = "foo"}
--	,PlayerDMZThresholdExceededOnTurn = {dummy = "foo"}
}

--m_Promises = m_AKWDIP_Data.Promises
m_AllPromises = m_AKWDIP_Data.Promises
m_PromisesToPlayer = {}
m_PromisesFromPlayer = {}
m_PromisesFromPlayerToPlayer = {}


m_TurnModEnabled = m_AKWDIP_Data.TurnModEnabled
m_DataLoaded = false

WarningStatements = {
	WARNING_DONT_SETTLE_NEAR_ME				=1
	,WARNING_STOP_CONVERTING_MY_CITIES		=2
	,WARNING_STOP_DIGGING_UP_ARTIFACTS		=3
	,WARNING_STOP_SPYING_ON_ME				=4
	,WARNING_TOO_MANY_TROOPS_NEAR_ME		=5
}

WarningPromiseMap = {
	WARNING_DONT_SETTLE_NEAR_ME				= "DONT_SETTLE_NEAR_ME"
	,WARNING_STOP_CONVERTING_MY_CITIES		= "DONT_CONVERT_MY_CITIES"
	,WARNING_STOP_DIGGING_UP_ARTIFACTS		= "DONT_DIG_UP_MY_ARTIFACTS"
	,WARNING_STOP_SPYING_ON_ME				= "DONT_SPY_ON_ME"
	,WARNING_TOO_MANY_TROOPS_NEAR_ME		= "KEEP_TROOPS_AWAY_FROM_ME"
}
PromiseWarningMap = {}
for k,v in pairs(WarningPromiseMap) do
	PromiseWarningMap[v] = k
end

PromiseDurations = {
	DONT_SETTLE_NEAR_ME			= GameInfo.DiplomaticActions.DIPLOACTION_KEEP_PROMISE_DONT_SETTLE_TOO_NEAR.Duration
	,DONT_CONVERT_MY_CITIES		= GameInfo.DiplomaticActions.DIPLOACTION_KEEP_PROMISE_DONT_CONVERT.Duration
	,DONT_DIG_UP_MY_ARTIFACTS	= GameInfo.DiplomaticActions.DIPLOACTION_KEEP_PROMISE_DONT_DIG_ARTIFACTS.Duration
	,DONT_SPY_ON_ME				= GameInfo.DiplomaticActions.DIPLOACTION_KEEP_PROMISE_DONT_SPY.Duration
	,KEEP_TROOPS_AWAY_FROM_ME	= GameInfo.DiplomaticActions.DIPLOACTION_MILITARY_REQUEST.Duration
}


--
----On GS:
----Troops promises are weird.
----	if you move all the troops away the turn the promise is made, and keep them away
----	the promise is fulfilled after 30/31 turns
----
---- if you leave one warrior there, it still fulfilled after 30/31 turns
----

---- Looks like, if you have more that 2 warriors in the zone on the 5th turn
---- the promise will be declared broken on turn 7




function AddPromise(requestor, requestedof, promiseType, promiseResponse)
	if not requestor or not requestedof or not promiseType or not promiseResponse then 
		print "AddPromise(requestor, requestedof, promiseType, promiseResponse)"
	end
	if type(promiseType) ~= "string" then 
		print("promiseType must be the string form")
		return
	end
	dprint ("AddPromise(requestor, requestedof, promiseType, promiseResponse)")
	dprint ("\t", requestor, requestedof, promiseType, promiseResponse)
	
	local currentTurn = Game.GetCurrentGameTurn()
	
	--if requestor == Game.GetLocalPlayer() then 
	--	print("We shouldn't be here, promise ai->toplayer should be being ignored!")
	--end
	
	if (promiseType ~= nil) 
	and (PromiseDurations[promiseType] ~= nil) 
	and (requestor ~= nil) 
	and (requestedof ~= nil) 
	then
		if promiseResponse == nil then 
			promiseResponse = PromiseResponses.Unknown
		end

		local newpromise = {}
		newpromise.TurnNoticed = currentTurn
		newpromise.TurnStarted = currentTurn
		newpromise.TurnEnds = currentTurn + PromiseDurations[promiseType]
		newpromise.Response = promiseResponse
		newpromise.Requestor = requestor
		newpromise.Requestee = requestedof
		newpromise.PromiseType = promiseType
		if (promiseType == "KEEP_TROOPS_AWAY_FROM_ME") and (promiseResponse == PromiseResponses.Accepted) then 
			newpromise.TurnsToBreach = m_DMZInitialGraceTurns
		end		

		local foundit = false
		if m_AllPromises ~= nil then 
			for k,promise in pairs(m_AllPromises) do 
				if promise.Requestor == requestor
				and promise.Requestee == requestedof
				and promise.PromiseType == promiseType then
					m_AllPromises[k] = newpromise
					foundit = true
					break
				end
			end
		end
				
		if not foundit then 
			table.insert(m_AllPromises, newpromise)
		end
	end
	
	LuaEvents.AKWDIP_PromisesChanged()
	
end
ExposedMembers.AKWDIP_AddPromise = AddPromise


function GetPromisesFromPlayer(playerID)
	return m_PromisesFromPlayer[playerID]
end

--This can directly replace all readonly references to m_Promises
function GetPromisesFromLocalPlayer()
	local localplayerID = Game.GetLocalPlayer()
	if m_PromisesFromPlayer[localplayerID] == nil then 
		return {}
	else
		return m_PromisesFromPlayer[localplayerID]
	end
end

function GetPromisesToPlayerID(playerID:number)
	if m_PromisesToPlayer[playerID] == nil then 
		return {}
	else
		return m_PromisesToPlayer[playerID]
	end
end
ExposedMembers.AKWDIP_GetPromisesToPlayerID = GetPromisesToPlayerID

function GetPromisesFromPlayerIDToPlayerID(fromplayerID, toplayerID)
	if m_PromisesFromPlayerToPlayer ~= nil
	and m_PromisesFromPlayerToPlayer[fromplayerID] ~= nil 
	and m_PromisesFromPlayerToPlayer[fromplayerID][toplayerID] ~= nil then 
		return m_PromisesFromPlayerToPlayer[fromplayerID][toplayerID] 
	end
	
	return {}	
end
ExposedMembers.AKWDIP_GetPromisesFromPlayerIDToPlayerID = GetPromisesFromPlayerIDToPlayerID

function GetPromisesOfType(promiseType)
	local retPromises = {}

	for k,promise in pairs(m_AllPromises) do 
		if promise.promiseType == promiseType then 
			table.insert(retPromises, promise)
		end
	end
	
	return retPromises
end
ExposedMembers.AKWDIP_GetPromisesOfType = GetPromisesOfType

function GetPromisesOfTypeFromPlayerID(promiseType, fromplayerID)
	local retPromises = {}

	for k,promise in pairs(m_AllPromises) do 
		if promise.PromiseType == promiseType 
		and promise.Requestee == fromplayerID then 
			table.insert(retPromises, promise)
		end
	end
	
	return retPromises
end
ExposedMembers.AKWDIP_GetPromisesOfTypeFromPlayerID = GetPromisesOfTypeFromPlayerID

function GetPromiseOfTypeFromPlayerIDToPlayerID(promiseType, fromplayerID, toplayerID)
	if m_PromisesFromPlayerToPlayer[fromplayerID]
	and m_PromisesFromPlayerToPlayer[fromplayerID][toplayerID] then 
		return m_PromisesFromPlayerToPlayer[fromplayerID][toplayerID][promisetype]
	end
	return nil
end
ExposedMembers.AKWDIP_GetPromiseOfTypeFromPlayerIDToPlayerID = GetPromiseOfTypeFromPlayerIDToPlayerID

function SaveDataToPlayerSlot(ePlayerID:number, sSlotName:string, data)
	dshowrectable(data, "SaveDataToPlayerSlot");
	local sData = serialize(data);
	PlayerConfigurations[ePlayerID]:SetValue(sSlotName, sData);
end

function LoadDataFromPlayerSlot(ePlayerID:number, sSlotName:string)
	local sData:string = PlayerConfigurations[ePlayerID]:GetValue(sSlotName);
	if sData == nil then print("WhatDidIPromise: WARNING: LoadDataFromPlayerSlot no data in slot", sSlotName, "for player", ePlayerID); return nil; end
	local tTable = loadstring(sData)();
	dshowrectable(tTable, "LoadDataFromPlayerSlot" );
	return tTable;
end

function SaveDataToGameSlot(sSlotName:string, data)
	--dprint("SaveDataToGameSlot (slot,type)",  sSlotName, type(data));
	
	local starttime, endtime
	starttime = Automation.GetTime()
	local sData = serialize(data);
	endtime = Automation.GetTime()
	dprint("\tSerialising ".. sSlotName .." with serialise() took", endtime-starttime);

	local datasize = #sData
	print("\tSaving ".. sSlotName ..",  " .. datasize .. " bytes")

	GameConfiguration.SetValue(sSlotName, sData);
	return datasize
end

function LoadDataFromGameSlot(sSlotName:string)
	--dprint("LoadDataFromGameSlot() (slot)", sSlotName);
	local starttime, endtime
	starttime = Automation.GetTime()
	local sData:string = GameConfiguration.GetValue(sSlotName);
	if sData == nil then print("WARNING: LoadDataFromGameSlot no data in slot", sSlotName); return nil; end

	print("\t" .. sSlotName .. " sData is " .. #sData .." bytes")
	
	local ls = assert(loadstring(sData))
	local tTable = ls();

	endtime = Automation.GetTime()
	dprint("\Loaded " .. #sData .. "bytes from ".. sSlotName ..", took", endtime-starttime);

	dshowrectable(tTable, "LoadDataFromGameSlot" );

	return tTable;
end

function SaveData()
	m_AKWDIP_Data.DataFormat = 3
	SaveDataToGameSlot("AKWDIP_Data", m_AKWDIP_Data)
end

function LoadData()
	print("WhatDidIPromise: --- LOADING AKWDIP_Data ---");
	local data:table = LoadDataFromGameSlot("AKWDIP_Data");
	if data ~= nil then -- but make sure we really loaded the data
		if data.DataFormat == nil then 	--pre-V1.8 data found. do conversion
			--shouldn't happen
			--through error, don't know what to do with this data
		elseif data.DataFormat == 3 then --v1.8 or later
			print("WhatDidIPromise: format 3 data exists");
			--do new load here
			return LoadDataFormat3(data)
		else 
			--through error, don't know what to do with this data
		end
	
	else --fallback to pre v1.8 data which should be in the localplayer slot
		local data:table = LoadDataFromPlayerSlot(Game.GetLocalPlayer(), "AKWDIP_Data");
		if data ~= nil then -- but make sure we really loaded the data
			print("WhatDidIPromise: v1.7 or earlier data exists, converting to format3");
			--LoadDataFormat2(data)
			

			data = ConvertV17DataToFormat3(data)
			return LoadDataFormat3(data)
		
		else --really really old data format, should probably be removed
			print("WhatDidIPromise: data seems to be nil! trying legacy fallback");
			data = LoadDataFromPlayerSlot(Game.GetLocalPlayer(), "AKP_Data");
			if data ~= nil then -- but make sure we really loaded the data
				print("WhatDidIPromise: legacy data exists, converting to format3");

				data = ConvertV17DataToFormat3(data)
				return LoadDataFormat3(data)
			end
			
			return false
		end
	end
end

function LoadDataFormat2(data)
	m_AKWDIP_Data = data
	
	if m_AKWDIP_Data.Promises then 
		m_Promises = m_AKWDIP_Data.Promises
		--this will change promises requested by the player (0) to promises requested the lowest unused index
		--as serialize doesn't correct deserialize arrays at inedx zero
		--rewrite as part of making workable for hotseat
	else
		--what was the purpose of the dummy entry?
		--Is it working around another serialize.lua limitation?
		m_AKWDIP_Data.Promises = {dummy = "foo"} 
		m_Promises = m_AKWDIP_Data.Promises
	end
	
	if m_AKWDIP_Data.TurnModEnabled then 
		m_TurnModEnabled = m_AKWDIP_Data.TurnModEnabled
	else
		m_AKWDIP_Data.TurnModEnabled = 999999
		m_TurnModEnabled = m_AKWDIP_Data.TurnModEnabled
	end

	return true
end

function ConvertV17DataToFormat3(data)
	local newdata = {}
	newdata.TurnModEnabled = data.TurnModEnabled or nil
	
	if data.Promises then 
		newdata.Promises = {}
		for reqor, promisesbytype in pairs(data.Promises) do
			if type(promisesbytype) == "table" then --needed skip the dummy record
				for promtype, promise in pairs(promisesbytype) do
					promise.Requestee = 0 -- pre 1.8 we only tracked promises from player 0
					promise.Requestor = reqor 
					promise.PromiseType	= promtype
					table.insert(newdata.Promises, promise)
				end
			end
		end
	end

	print("conversion completed, result:")
	dshowrectable(newdata)

	return newdata
end

function LoadDataFormat3(data)
	m_AKWDIP_Data.TurnModEnabled = data.TurnModEnabled or nil
	
	m_AKWDIP_Data.Promises = data.Promises or {dummy = "foo"} --- why dummy=foo? can I get rid of this?

	m_AllPromises = m_AKWDIP_Data.Promises
	
	m_TurnModEnabled = m_AKWDIP_Data.TurnModEnabled or 999999
	
	return true
end

function ReBuildPromiseIndexes()
	dprint("ReBuildPromiseIndexes()")
	m_PromisesToPlayer = {}
	m_PromisesFromPlayer = {}
	m_PromisesFromPlayerToPlayer = {}

--	for k,promise in ipairs(m_AllPromises) do 
-- needs to be pairs, as expired promises leave gaps in the table
	for k,promise in pairs(m_AllPromises) do 
		if promise.Requestor ~= nil then 
			m_PromisesToPlayer[promise.Requestor] = m_PromisesToPlayer[promise.Requestor] or {}
			m_PromisesToPlayer[promise.Requestor][promise.PromiseType] = promise

			m_PromisesFromPlayer[promise.Requestee] = m_PromisesFromPlayer[promise.Requestee] or {}
			m_PromisesFromPlayer[promise.Requestee][promise.PromiseType] = promise
			
			m_PromisesFromPlayerToPlayer[promise.Requestee] = m_PromisesFromPlayerToPlayer[promise.Requestee] or {}
			m_PromisesFromPlayerToPlayer[promise.Requestee][promise.Requestor] = m_PromisesFromPlayerToPlayer[promise.Requestee][promise.Requestor] or {}
			m_PromisesFromPlayerToPlayer[promise.Requestee][promise.Requestor][promise.PromiseType] = promise
		else 
			print ("ReBuildPromiseIndexes: m_AllPromises[" .. k .. "].Requestor was nil!" )
			dprint(promise)
		end
	end
end

function OnTurnBegin()
	local currentTurn = Game.GetCurrentGameTurn()

	--review all promises for all players
	for k,promise in pairs(m_AllPromises) do	
		--delete if expired
		if (promise.TurnEnds == nil)  or  (promise.TurnEnds < currentTurn) then 
			m_AllPromises[k] = nil
		--delete if requestee has vanished
		elseif not Players[promise.Requestee] then 
			m_AllPromises[k] = nil
		--delete if requestor has vanished
		elseif not Players[promise.Requestor] then 
			m_AllPromises[k] = nil
		--delete if requestee and requestor are at war
		elseif Players[promise.Requestee]:GetDiplomacy() 
		and Players[promise.Requestee]:GetDiplomacy():IsAtWarWith(promise.Requestor) then
			m_AllPromises[k] = nil
		--delete if requestee is dead
		elseif not Players[promise.Requestee]:IsAlive() then 
			m_AllPromises[k] = nil
		--delete if requestor is dead
		elseif not Players[promise.Requestor]:IsAlive() then 
			m_AllPromises[k] = nil
		--work out DMZ status is mil promise and requestee is human (maybe redundant, can requestee ever be non-human?)
		elseif promise.PromiseType == "KEEP_TROOPS_AWAY_FROM_ME" 
		and Players[promise.Requestee]:IsHuman() then 
			dprint(promise, "WhatDidIPromise: checking for imminent DMZ breaches against playerID: " .. promise.Requestor)
			local graceTurnsRemaining = (promise.TurnStarted + m_DMZInitialGraceTurns)- currentTurn 
			local isDMZUnitThresholdBreached = IsDMZUnitThresholdBreached(promise.Requestee, promise.Requestor)

			if graceTurnsRemaining >= -2 then 
				--minus two, because its the state after three turns that matters, although the
				--promise isn't declared broken until turn 5; i think!
				promise.TurnsToBreach = graceTurnsRemaining
			else
				promise.TurnsToBreach = m_DMZMaxTurnsOverThreshold 
				----If there are more than 2 units in the DMZ zone for
				----even a single turn, after the initial 5 turn grace period, results in the
				----promise being broken
				if isDMZUnitThresholdBreached then
					if not promise.TurnsOverDMZThreshold then 
						promise.TurnsOverDMZThreshold = 1
					else
						promise.TurnsOverDMZThreshold = 1 + promise.TurnsOverDMZThreshold 
					end
					promise.TurnsToBreach = m_DMZMaxTurnsOverThreshold - promise.TurnsOverDMZThreshold
				else
					promise.TurnsOverDMZThreshold = 0
					promise.TurnsToBreach = m_DMZMaxTurnsOverThreshold
				end
			end		

			if isDMZUnitThresholdBreached and opt.ShowNotificationForImminentBreachOf_KEEP_TROOPS_AWAY_FROM_ME then 
				local notificationData:table = {}
				notificationData.Message = Locale.Lookup("LOC_AKWDIP_IMMINENT_DMZ_BREACH_NOTIFICATION_HEADER")
				notificationData.Icon = "ICON_NOTIFICATION_AKWDIP_IMMINENT_DMZ_BREACH" 
				notificationData.AlwaysUnique = true
				if promise.TurnsToBreach == 0 then 
					notificationData.Summary = Locale.Lookup("LOC_AKWDIP_NOTIFICATION_DMZ_BREACH_NOW_TEXT",
						Locale.Lookup("LOC_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName() .. "_NAME"))
					NotificationManager.SendNotification(promise.Requestee, AKWDIP_IMMINENT_DMZ_BREACH_NOTIFICATIONHASH, notificationData)
				elseif promise.TurnsToBreach == 1 then 
					notificationData.Summary = Locale.Lookup("LOC_AKWDIP_NOTIFICATION_DMZ_BREACH_IMMINENT_TEXT",
						Locale.Lookup("LOC_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName() .. "_NAME"),
						promise.TurnsToBreach)
					NotificationManager.SendNotification(promise.Requestee, AKWDIP_IMMINENT_DMZ_BREACH_NOTIFICATIONHASH, notificationData)
				end
			end
		end
	end
	SaveData()

	LuaEvents.AKWDIP_PromisesChanged()		
	
	dshowrectable(m_AllPromises, "m_AllPromises")
end

--Moved all of this to onTurnBegin to ensure it only gets called once, and do everything for all the players
function OnPlayerTurnActivated(playerID:number, isFirstTimeThisTurn:boolean)
--	dprint("WhatDidIPromise: AKWDIP_Main: t".. Game.GetCurrentGameTurn() .. " OnPlayerTurnActivated for ", playerID)
--	if not isFirstTimeThisTurn then 
--		dprint("\tIs not FirstTimeThisTurn")
--		return
--	end
--	
--	local localPlayerID:number = Game.GetLocalPlayer();
--	local currentTurn = Game.GetCurrentGameTurn()
--	if localPlayerID == playerID then
--		dprint("WhatDidIPromise: AKWDIP_Main: t".. currentTurn .. " OnPlayerTurnActivated for local player")
--		if ExposedMembers.DonePromiseReviewForTurn and ExposedMembers.DonePromiseReviewForTurn == currentTurn then
--			--as there might be more than one instance of the DiplomacyRibbon, 
--			--we have to ensure this doesn't happen twice in a single turn
--			--Now that this isn't in DiplomacyRibbon this shouldn't be needed,
--			--but there's no harm leaving it in just to be sure
--			return
--		else
--			ExposedMembers.DonePromiseReviewForTurn = currentTurn
--		end
--
--
--
--		local pLocalPlayer = Players[localPlayerID]
--		local localPlayerDiplomacy:table = pLocalPlayer:GetDiplomacy();
--
--		--review all promises for all players
--		for player, promises in pairs(m_Promises) do
--			local promiseTypeRecordsToDelete = {}
--		
--			if type(promises) == "table" then 
--				dshowrectable(promises, "promises")
--				for promiseType, promise in pairs(promises) do
--					--mark expired promised for removal
--					if (promise.TurnEnds == nil)  or  (promise.TurnEnds < currentTurn) then 
--						table.insert(promiseTypeRecordsToDelete, promiseType)
--					--mark promises with players we are now at with for removal
--					elseif localPlayerDiplomacy:IsAtWarWith(player) then 
--						table.insert(promiseTypeRecordsToDelete, promiseType)
--					--check if we have troops in a milpromzone
--					elseif promiseType == "KEEP_TROOPS_AWAY_FROM_ME" and localPlayerID ~= player then 
--						dprint(promises, "WhatDidIPromise: checking for imminent DMZ breaches against playerID:" .. player)
--						local graceTurnsRemaining = (promise.TurnStarted + m_DMZInitialGraceTurns)- currentTurn 
--						local isDMZUnitThresholdBreached = IsDMZUnitThresholdBreached(localPlayerID, player)
--
--						if graceTurnsRemaining >= -2 then 
--							--minus two, because its the state after three turns that matters, although the
--							--promise isn't declared broken until turn 5; i think!
--							promise.TurnsToBreach = graceTurnsRemaining
--						else
--							promise.TurnsToBreach = m_DMZMaxTurnsOverThreshold 
--						----If there are more than 2 units in the DMZ zone for
--						----even a single turn, after the initial 5 turn grace period, results in the
--						----promise being broken
--							if isDMZUnitThresholdBreached then
--								if not promise.TurnsOverDMZThreshold then 
--									promise.TurnsOverDMZThreshold = 1
--								else
--									promise.TurnsOverDMZThreshold = 1 + promise.TurnsOverDMZThreshold 
--								end
--								promise.TurnsToBreach = m_DMZMaxTurnsOverThreshold - promise.TurnsOverDMZThreshold
--						--		
--						--		dprint("DMZ Threshold exceeded for player", player, m_DMZMaxTurnsOverThreshold - promise.TurnsOverDMZThreshold, "turns until breach")
--						--		
--							else
--								promise.TurnsOverDMZThreshold = 0
--								promise.TurnsToBreach = m_DMZMaxTurnsOverThreshold
--							end
--						end
--
--						if isDMZUnitThresholdBreached and opt.ShowNotificationForImminentBreachOf_KEEP_TROOPS_AWAY_FROM_ME then 
--							local notificationData:table = {}
--							notificationData.Message = Locale.Lookup("LOC_AKWDIP_IMMINENT_DMZ_BREACH_NOTIFICATION_HEADER")
--							notificationData.Icon = "ICON_NOTIFICATION_AKWDIP_IMMINENT_DMZ_BREACH" 
--							notificationData.AlwaysUnique = true
--							if promise.TurnsToBreach == 0 then 
--								notificationData.Summary = Locale.Lookup("LOC_AKWDIP_NOTIFICATION_DMZ_BREACH_NOW_TEXT",
--									Locale.Lookup("LOC_" .. PlayerConfigurations[player]:GetCivilizationTypeName() .. "_NAME"))
--								NotificationManager.SendNotification(localPlayerID, AKWDIP_IMMINENT_DMZ_BREACH_NOTIFICATIONHASH, notificationData)
--							elseif promise.TurnsToBreach == 1 then 
--								notificationData.Summary = Locale.Lookup("LOC_AKWDIP_NOTIFICATION_DMZ_BREACH_IMMINENT_TEXT",
--									Locale.Lookup("LOC_" .. PlayerConfigurations[player]:GetCivilizationTypeName() .. "_NAME"),
--									promise.TurnsToBreach)
--								NotificationManager.SendNotification(localPlayerID, AKWDIP_IMMINENT_DMZ_BREACH_NOTIFICATIONHASH, notificationData)
--							end
--						end
--					end
--				end
--				
--				--remove promises marked for deletion
--				for k,v in pairs(promiseTypeRecordsToDelete) do 
--					promises[v] = nil
--				end
--				promiseTypeRecordsToDelete = {}
--			end
--		end
--		
--		SaveDataToPlayerSlot(localPlayerID, "AKWDIP_Data", m_AKWDIP_Data)
--
--
--		LuaEvents.AKWDIP_PromisesChanged()		
--	end
--
--	dprint(m_AKWDIP_Data)
end

--what does this mean for hotseat\multiplayer games? Does it fire more than once?
--maybe replace with OnTurnEnd so it only saves once and after all players including the AI?
function OnLocalPlayerTurnEnd()
	dprint("WhatDidIPromise: AKWDIP_Main: t".. Game.GetCurrentGameTurn() .. " OnLocalPlayerTurnEnd")
	--local localPlayerID:number = Game.GetLocalPlayer();
	--SaveDataToPlayerSlot(localPlayerID, "AKWDIP_Data", m_AKWDIP_Data)
	
	SaveData()

	return
end

-- this event is called ONLY when loading a save file
function OnLoadComplete()
	dprint("WhatDidIPromise: AKWDIP_Main: t".. Game.GetCurrentGameTurn() .. " OnLoadComplete")
	--load saved promise info here
	m_DataLoaded = LoadData()
	
	ReBuildPromiseIndexes()
end

--this seems to be called multiple times when loading from autosave, and 'Game' is nil 
--at least some of those times, ultimately works but, perhaps move this to OnTurnBegin maybe?
function OnLoadScreenClose()
	if Game then 
		dprint("WhatDidIPromise: AKWDIP_Main: t".. Game.GetCurrentGameTurn() .. " OnLoadScreenClose")
		local localPlayerID:number = Game.GetLocalPlayer();
		
		if not m_DataLoaded then 
			dprint("WhatDidIPromise: data not loaded, set TurnModEnabled and save")
			m_AKWDIP_Data.TurnModEnabled = Game.GetCurrentGameTurn()
			--SaveDataToPlayerSlot(localPlayerID, "AKWDIP_Data", m_AKWDIP_Data)
			SaveData()
		end

		Events.DiplomacyStatement.Add( OnDiplomacyStatement );
	end
end

---Is this really the only way to tell the AI regards us as having broken a troop promise?!
function IsNotificationOfTroopPromiseBreach(pNotification)
	if pNotification ~= nil then
		if pNotification:GetTypeName() == "NOTIFICATION_DIPLOMATIC_PLEDGE_TO_BROKEN" then 
	
			local notificationSummary = pNotification:GetSummary()
			dprint ("WhatDidIPromise: notificationSummary    : ", notificationSummary)
	
			local troopPromises = GetPromisesOfType("KEEP_TROOPS_AWAY_FROM_ME")
			for _,promise in ipairs(troopPromises) do
				local brokeTroopPromiseString = Locale.Lookup("LOC_NOTIFICATION_DIPLO_PLEDGE_TO_BROKEN_SUMMARY", 
					Locale.Lookup("LOC_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName() .. "_DESCRIPTION"),
					Locale.Lookup("LOC_NOTIFICATION_PROMISE_TYPE_ON_BORDER")
				)
	
				dprint ("WhatDidIPromise: brokeTroopPromiseString: ", brokeTroopPromiseString)
				if brokeTroopPromiseString == notificationSummary then 
					dprint("WhatDidIPromise: broke troop promise to", Locale.Lookup("LOC_" .. PlayerConfigurations[promise.Requestor]:GetCivilizationTypeName() .. "_DESCRIPTION"))
					return true, promise
				end
			end
		end
	end
		
	return false, nil
end


function ClearPromises(requestee, requestor, promisetype)
	if promisetype ~= nil and type(promisetype) ~= "string" then 
		print("WhatDidIPromise: promisetype must be the string form, or nil to clear all")
		return
	end

	local promisestodelete = {}
	for k,v in pairs(m_AllPromises) do
		if v.Requestee == requestee 
		and v.Requestor == requestor
		and ((v.PromiseType == promisetype) or (promisetype == nil))
		then 
			table.insert(promisestodelete, k)
		end
	end
	
	for i=#promisestodelete, 1 do
		table.remove(m_AllPromises, promisestodelete[i])
	end
	
	LuaEvents.AKWDIP_PromisesChanged()
end
ExposedMembers.AKWDIP_ClearPromises = ClearPromises


function OnNotificationAdded( playerID:number, notificationID:number )
	local pPlayer : table = PlayerConfigurations[playerID];
	if(not pPlayer:IsAlive())then return end;
	local pNotification : table = NotificationManager.Find( playerID, notificationID );
	if pNotification ~= nil then
		if pNotification:IsVisibleInUI() then
			--print("WhatDidIPromise:    OnNotificationAdded():",notificationID, "for type "..tostring(pNotification:GetMessage()) );	--debug
			local promiseBreached, promise =  IsNotificationOfTroopPromiseBreach(pNotification)
		
			if promiseBreached then 
				ClearPromises(promise.Requestee, promise.Requestor, PromiseTypeNames[promise.PromiseType]) 
			end

		end
	end
end

function onAKWDIP_PromisesChanged()
	SaveData()
	ReBuildPromiseIndexes()
	--local localPlayerID:number = Game.GetLocalPlayer();
	--SaveDataToPlayerSlot(localPlayerID, "AKWDIP_Data", m_AKWDIP_Data)
end

function OnShutdown()
	ExposedMembers.AKWDIP_Options = nil
end

function Initialize()
	ContextPtr:SetShutdown(OnShutdown);

    Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone);
	
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
	-- loading persistent data
	Events.LoadComplete.Add( OnLoadComplete ); -- fires ONLY when loading a game from a save file, when it's ready to start (i.e. circle button appears)
	Events.LoadScreenClose.Add(OnLoadScreenClose)

	--Events.PlayerTurnActivated.Add(OnPlayerTurnActivated)
	Events.TurnBegin.Add(OnTurnBegin)
	
	Events.NotificationAdded.Add(OnNotificationAdded)
	
	LuaEvents.AKWDIP_PromisesChanged.Add(onAKWDIP_PromisesChanged)

	LoadData()	--this seems to be redundant? 211018
end
Initialize();

