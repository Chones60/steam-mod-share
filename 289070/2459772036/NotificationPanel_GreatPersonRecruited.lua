local BASE_RegisterHandlers = RegisterHandlers
local otherPlayerRecruitedGreatPersonNotificationHash = DB.MakeHash("NOTIFICATION_OTHER_PLAYER_RECRUITED_GREATPERSON")

local function GetPlayerNameToLocalPlayer(playerID:number)
    local localPlayerID = Players[Game.GetLocalPlayer()];

	if localPlayerID:GetDiplomacy():HasMet(playerID) then
        return PlayerConfigurations[playerID]:GetPlayerName();
    else
        return "LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN";
    end
end

local function CreateGreatPersonRecruitedNotificationData(playerID:number, greatPersonID:number)
	local greatPersonDetails = GameInfo.GreatPersonIndividuals[greatPersonID]

	local recruitingPlayer = Locale.Lookup(GetPlayerNameToLocalPlayer(playerID));
	local greatPersonName = Locale.Lookup(greatPersonDetails.Name)
	local greatPersonType = Locale.Lookup("LOC_" .. greatPersonDetails.GreatPersonClassType .. "_NAME")

	local notificationData:table = {}
	notificationData.Message = Locale.Lookup("LOC_NOTIFICATION_OTHER_PLAYER_RECRUITED_GREATPERSON_MESSAGE")
	notificationData.Summary = Locale.Lookup("LOC_NOTIFICATION_OTHER_PLAYER_RECRUITED_GREATPERSON_SUMMARY",
											 recruitingPlayer, greatPersonType, greatPersonName)
	notificationData.Icon = "ICON_NOTIFICATION_OTHER_PLAYER_RECRUITED_GREATPERSON"

	-- We are using the same notification type, but our contents are different, so tell the manager that there is no redundancy
	notificationData.AlwaysUnique = true

	return notificationData
end

local function OnUnitAddedToMapNotifyLocalAboutGreatPerson(playerID:number, unitID:number)
	local player:table = Players[playerID]
	local unit:table = player:GetUnits():FindID(unitID)

	if not unit then
		return
	end

	local greatPerson:table = unit:GetGreatPerson()
	local localPlayerID = Game.GetLocalPlayer()

	if greatPerson:IsGreatPerson() and playerID ~= localPlayerID then
		local notificationData:table = CreateGreatPersonRecruitedNotificationData(playerID, greatPerson:GetIndividual())
		NotificationManager.SendNotification(localPlayerID, otherPlayerRecruitedGreatPersonNotificationHash, notificationData)
	end
end

function RegisterHandlers()
	BASE_RegisterHandlers()

	g_notificationHandlers[otherPlayerRecruitedGreatPersonNotificationHash] = MakeDefaultHandlers()
	g_notificationHandlers[otherPlayerRecruitedGreatPersonNotificationHash].AddSound = "ALERT_NEUTRAL"
	g_notificationHandlers[otherPlayerRecruitedGreatPersonNotificationHash].Activate = OnClaimGreatPersonActivate
end

local function Initialize()
    -- Add the notify event when the game has finished loading
	--  to prevent a notification being displayed for each great person
	--  on the map when the game is loading
	Events.LoadGameViewStateDone.Add(function()
		Events.UnitAddedToMap.Add(OnUnitAddedToMapNotifyLocalAboutGreatPerson);
	end)
end

Initialize()