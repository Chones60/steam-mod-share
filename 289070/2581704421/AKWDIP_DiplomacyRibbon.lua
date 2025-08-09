print("WhatDidIPromise: Loading AKWDIP_DiplomacyRibbon.lua")
if ExposedMembers.AKWDIP_Options ~= nil then 
	opt = ExposedMembers.AKWDIP_Options 
else
	include("AKWDIP_DefaultOptions.lua")
end

include("AKWDIP_Common.lua")


function AKWDIP_AddLeader(iconName : string, playerID : number, kProps: table)
	--used for basegame with no mods, or with just HSE or DCP
    local oLeaderIcon:object = AKWDIP_HookedFunction(iconName, playerID, kProps);

	local promisett = GetPromisesTTString(playerID)

	if oLeaderIcon ~= nil then
		dprint("AKWDIP_AddLeader: oLeaderIcon was nil! only pregame or in autoplay?")
		oLeaderIcon:AppendTooltip(promisett);
	end
	
	return oLeaderIcon
end

function AKWDIP_AddLeaderBLI(iconName : string, playerID : number, kProps: table)
	--used for BLI with or without HSE or DCP
    local oLeaderIcon:object, instance = AKWDIP_HookedFunction(iconName, playerID, kProps);

	local promisett = GetPromisesTTString(playerID)
	if #promisett > 0 then 
		promisett = "[NEWLINE]-----------------------------------------------" .. promisett
	end

	local oldTT = oLeaderIcon.Controls.Relationship:GetToolTipString()
	
	if oldTT then 
		promisett = oldTT .. promisett
	end
	oLeaderIcon.Controls.Relationship:SetToolTipString(promisett);
	
	return oLeaderIcon, instance;
end

function AKWDIP_GetExtendedTooltip(playerID:number)
	--used for EDR and CQUI with or without HSE or DCP
	local promisett = GetPromisesTTString(playerID)
	if #promisett > 0 then 
		promisett = "[NEWLINE]-----------------------------------------------" .. promisett
	end

	return AKWDIP_HookedFunction(playerID) .. promisett
end


local basefilename = GetBasefilename("DiplomacyRibbon")
if basefilename then 
	print("WhatDidIPromise: AKWDIP_DiplomacyRibbon.lua using " .. basefilename .. " as base file");
	include(basefilename)
	if Initialize then 
		dprint("WhatDidIPromise: AKWDIP_DiplomacyRibbon.lua loaded basefile: ",basefilename );
	else
		print("WhatDidIPromise: FATAL ERROR AKWDIP_DiplomacyRibbon.lua hasn't loaded a basefile, things will be broken!")
	end
else
	print("WhatDidIPromise: FATAL ERROR AKWDIP_DiplomacyRibbon.lua couldn't choose a basefile, things will be broken!")
end

local hookee, hooker = GetHookeeAndHooker("DiplomacyRibbon")
if hookee and hooker then 
	print("WhatDidIPromise: AKWDIP_DiplomacyRibbon.lua hooking " .. hookee .. ", with " .. hooker);
	loadstring("AKWDIP_HookedFunction = "..hookee)()
	loadstring(hookee .. " = " .. hooker)()
	if AKWDIP_HookedFunction then 
		dprint("WhatDidIPromise: AKWDIP_DiplomacyRibbon.lua hooked " .. hookee .. ", with " .. hooker);
	else
		print("WhatDidIPromise: FATAL ERROR AKWDIP_DiplomacyRibbon.lua Hook failed, things will be broken!")
	end
else
	print("WhatDidIPromise: FATAL ERROR AKWDIP_DiplomacyRibbon.lua couldn't choose a hookee\hooker, things will be broken!")
end


function OnAKWDIP_PromisesChanged()
	dprint("WhatDidIPromise: DiploRibbon caught AKWDIP_PromisesChanged");
	--call base func to update the leadericons
	UpdateLeaders();
end


function GetPromisesTTString(playerID:number, localPlayerID:number)
	--local localPlayerID:number
	if localPlayerID == nil then 
		if Game then 
			localPlayerID = Game.GetLocalPlayer();
		end
		if localPlayerID == nil then 
			return ""
		end
	end

--	UpdatePromiseRecords()

	local promiseAcceptedTT = {}
	local promiseRefusedTT = {}
	local promiseUnknownTT = {}

	--don't display for ourself
	if localPlayerID ~= playerID then
		local localPlayer:table = Players[localPlayerID];
		local currentTurn = Game.GetCurrentGameTurn()

		local playerPromises = {}
		--playerPromises = GetPromisesToPlayerID(playerID)
		playerPromises = GetPromisesFromPlayerIDToPlayerID(localPlayerID, playerID)

--		dprint("GetPromisesTTString(localPlayerID, playerID):", localPlayerID, playerID)
--		dshowrectable(playerPromises, "playerPromises")
		
		if playerPromises then 
			for promiseType, promise in pairs(playerPromises) do
				
				if promise.TurnStarted and promise.TurnEnds and (promise.Response == PromiseResponses.Accepted) then 
					table.insert(promiseAcceptedTT, Locale.Lookup("LOC_AKWDIP_ACCEPTED_" .. promiseType 
						,1+ promise.TurnEnds - currentTurn))
						
				elseif promise.TurnStarted and promise.TurnEnds and (promise.Response == PromiseResponses.Refused) then 
					table.insert(promiseRefusedTT, Locale.Lookup("LOC_AKWDIP_REFUSED_" .. promiseType 
						,1+ promise.TurnEnds - currentTurn))
						
				elseif (promise.Response == PromiseResponses.Unknown) and (promiseType == "KEEP_TROOPS_AWAY_FROM_ME") then
					--no response to "KEEP_TROOPS_AWAY_FROM_ME" means we are at war so, so no one cares about the request anymore

				elseif promise.TurnStarted and promise.TurnEnds and (promise.Response == PromiseResponses.Unknown) then 
					-- if we get here either we somehow missed the response message, or the player ignored the request somehow
					-- so just show that they asked
					table.insert(promiseUnknownTT, Locale.Lookup("LOC_AKWDIP_REQUESTED_" .. promiseType 
						,1+ promise.TurnEnds - currentTurn))
				else
					--should be impossible to  get here now that we're tracking the diplo conversation rather than
					-- using the flaky player:GetDiplomacy()::IsPromiseMade(), but just in case...
					table.insert(promiseUnknownTT,	Locale.Lookup("LOC_AKWDIP_REQUESTED_" .. promiseType .. "_NODATE"))

				end
			end		
		end
	end
	
	local allpromisesTT = {}
	
	local promiseString = ""
	if #promiseAcceptedTT > 0 then 
		table.insert(allpromisesTT, "[NEWLINE]" ..  Locale.Lookup("LOC_AKWDIP_PROMISE_ACCPETED_HEADER") .. "[NEWLINE]" .. table.concat(promiseAcceptedTT, "[NEWLINE]"))
	end
	if #promiseRefusedTT > 0 then 
		table.insert(allpromisesTT, "[NEWLINE]" ..  Locale.Lookup("LOC_AKWDIP_PROMISE_REFUSED_HEADER") .. "[NEWLINE]" .. table.concat(promiseRefusedTT, "[NEWLINE]"))
	end
	if #promiseUnknownTT > 0 then 
		table.insert(allpromisesTT, "[NEWLINE]" ..  Locale.Lookup("LOC_AKWDIP_PROMISE_UNKNOWN_HEADER") .. "[NEWLINE]" .. table.concat(promiseUnknownTT, "[NEWLINE]"))
	end

	if opt.DebugMode then 
		promiseString = "[NEWLINE]WDIP Enabled"
	end
	promiseString =  promiseString .. table.concat(allpromisesTT, "[NEWLINE]")
	
  return promiseString;
end
ExposedMembers.AKWDIP_GetPromisesTTString = GetPromisesTTString

function Initialise()
	Events.LoadScreenClose.Add(OnLoadScreenClose)
end

function OnLoadScreenClose()
	LuaEvents.AKWDIP_PromisesChanged.Add( OnAKWDIP_PromisesChanged);
end

Initialise()
