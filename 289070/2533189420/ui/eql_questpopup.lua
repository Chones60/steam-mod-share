include("InstanceManager");
include("ModalScreen_PlayerYieldsHelper");
include("AnimSidePanelSupport");
include("SupportFunctions");
include("GameCapabilities");

g_IsXP1Active = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9");
g_IsXP2Active = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68");

local m_TopPanelConsideredHeight:number = 0;

local unitIM:table = InstanceManager:new("CityStateRowInstance", "CityStateBase", Controls.TrainUnitStack);
local districtIM:table = InstanceManager:new("CityStateRowInstance", "CityStateBase", Controls.BuildDistrictStack);
local eurekaIM:table = InstanceManager:new("CityStateRowInstance", "CityStateBase", Controls.TriggerEurekaStack);
local inspirationIM:table = InstanceManager:new("CityStateRowInstance", "CityStateBase", Controls.TriggerInspirationStack);
local tradeIM:table = InstanceManager:new("CityStateRowInstance", "CityStateBase", Controls.TradeRouteStack);
local greatPersonIM:table = InstanceManager:new("CityStateRowInstance", "CityStateBase", Controls.RecruitGreatPersonStack);
local religionIM:table = InstanceManager:new("CityStateRowInstance", "CityStateBase", Controls.ReligiousConversionStack);
local barbarianIM:table = InstanceManager:new("CityStateRowInstance", "CityStateBase", Controls.ClearBarbarianCampStack);

local instanceManagers = {
	["QUEST_SEND_TRADE_ROUTE"] = tradeIM,
	["QUEST_TRAIN_UNIT_TYPE"] = unitIM,
	["QUEST_RECRUIT_GREAT_PERSON_CLASS"] = greatPersonIM,
	["QUEST_ZONE_DISTRICT_TYPE"] = districtIM,
	["QUEST_TRIGGER_TECH_BOOST"] = eurekaIM,
	["QUEST_TRIGGER_CIVIC_BOOST"] = inspirationIM,
	["QUEST_CONVERT_CAPITAL_TO_RELIGION"] = religionIM,
	["QUEST_CLEAR_BARBARIAN_CAMP"] = barbarianIM
}

local m_OpenListID:number = Input.GetActionId("OpenList");
local m_isOpen:boolean = false;

function OnInputActionTriggered(actionId:number)
    if actionId == m_OpenListID and not m_isOpen then
        Open();
    elseif actionId == m_OpenListID and m_isOpen then
		Close();
	end
end

function Open()
	print("Open()");
    local localPlayer = Game.GetLocalPlayer();
    if localPlayer == -1 or not Players[localPlayer]:IsTurnActive() then return; end

	populateScreen(); 
	CloseOtherPanels();

    -- Queue the screen as a popup, but we want it to render at a desired location in the hierarchy, not on top of everything.
    if not UIManager:IsInPopupQueue(ContextPtr) then
        local kParameters = {};
        kParameters.RenderAtCurrentParent = true;
        kParameters.InputAtCurrentParent = true;
        kParameters.AlwaysVisibleInQueue = true;
        UIManager:QueuePopup(ContextPtr, PopupPriority.Low, kParameters);
        -- Change our parent to be 'Screens' so the navigational hooks draw on top of it.
        ContextPtr:ChangeParent(ContextPtr:LookUpControl("/InGame/Screens"));
        UI.PlaySound("UI_Screen_Open");
    end

    -- From ModalScreen_PlayerYieldsHelper
    if not RefreshYields() then
        Controls.Vignette:SetSizeY(m_TopPanelConsideredHeight);
    end
	
    -- From Civ6_styles: FullScreenVignetteConsumer
    Controls.ScreenAnimIn:SetToBeginning();
    Controls.ScreenAnimIn:Play();

	m_isOpen = true;
	print("Open() done");
end

function Close()
	print("Close()");
    if UIManager:DequeuePopup(ContextPtr) then
        UI.PlaySound("UI_Screen_Close");
		m_isOpen = false;
    end
	print("Close() done");
end

function CloseOtherPanels()
    LuaEvents.LaunchBar_CloseTechTree();
    LuaEvents.LaunchBar_CloseCivicsTree();
    LuaEvents.LaunchBar_CloseGovernmentPanel();
    LuaEvents.LaunchBar_CloseReligionPanel();
    LuaEvents.LaunchBar_CloseGreatPeoplePopup();
    LuaEvents.LaunchBar_CloseGreatWorksOverview();
    if g_IsXP1Active then
        LuaEvents.GovernorPanel_Close();
        LuaEvents.HistoricMoments_Close();
    end
    if g_IsXP2Active then
        LuaEvents.Launchbar_Expansion2_ClimateScreen_Close();
    end
end

function getIconName( questName:string, questType:string )
	
	local iconName = "";

	local questLocName = "LOC_"..questType.."_INSTANCE_NAME"

	if questType == "QUEST_TRAIN_UNIT_TYPE" then
		for info in GameInfo.Units() do	
			if questName == Locale.Lookup(questLocName, info.Name) then
				iconName = info.UnitType;
				break;
			end
		end
	elseif questType == "QUEST_ZONE_DISTRICT_TYPE" then
		for info in GameInfo.Districts() do	
			if questName == Locale.Lookup(questLocName, info.Name) then
				iconName = info.DistrictType;
				break;
			end
		end
	elseif questType == "QUEST_RECRUIT_GREAT_PERSON_CLASS" then
		for info in GameInfo.GreatPersonClasses() do	
			if questName == Locale.Lookup(questLocName, info.Name) then
				iconName = info.GreatPersonClassType;
				break;
			end
		end
	elseif questType == "QUEST_TRIGGER_TECH_BOOST" then
		for info in GameInfo.Technologies() do	
			if questName == Locale.Lookup(questLocName, info.Name) then
				iconName = info.TechnologyType;
				break;
			end
		end		
	else
		for info in GameInfo.Civics() do	
			if questName == Locale.Lookup(questLocName, info.Name) then
				iconName = info.CivicType;
				break;
			end
		end
	end

	return iconName;
end

--Generate an instance of City-State row
function populateQuest( kCityState:table )
	--print("populateQuest()");
	local kInst				:table = nil;
	local cityStateName		:string = Locale.ToUpper( Locale.Lookup(kCityState.Name) )
	local questIconName		:string = nil;
	local questName			:string = kCityState.Quests.Name;
	local questType			:string = kCityState.Quests.Type;
	--print(questType);
	--print(questName);
	kInst = instanceManagers[questType]:GetInstance();

	if questType == "QUEST_SEND_TRADE_ROUTE" then
		questIconName = "TRADEROUTE_EQL";
	elseif questType == "QUEST_CONVERT_CAPITAL_TO_RELIGION" then
		questIconName = "RELIGION"
	elseif questType == "QUEST_CLEAR_BARBARIAN_CAMP" then
		questIconName = "CIVILIZATION_BARBARIAN"
	else
		questIconName = getIconName(questName, questType);
	end

	--print("Quest Icon Name: "..questIconName);

	-- Set name, truncate if necessary
	kInst.NameLabel:SetText( cityStateName );
	local targetSize:number = (kInst.NameButton:GetSizeX() - 12);
	TruncateStringWithTooltip(kInst.NameLabel, targetSize, cityStateName);

	kInst.NameLabel:SetColor( kCityState.ColorSecondary );
	
	kInst.Icon:SetIcon( "ICON_"..kCityState.CivType );
	kInst.Icon:SetColor( kCityState.ColorSecondary );
	
	kInst.EnvoyCount:SetText( kCityState.EnvoyTokens );
	
	kInst.QuestIcon:SetIcon( "ICON_"..questIconName );
	kInst.QuestIcon:SetToolTipString(questName);
	
	--print("populateQuest() Done");
	return kInst;
end

function populateScreen()
	print("populateScreen()");

	for questType, instanceManager in pairs(instanceManagers) do
		instanceManager:ResetInstances();
	end

	getData(); --TODO: Use Event questChanged to avoid recalling data every time

	local function SortCityStates(t, a, b)
        if t[a].Quests.Type == nil or t[b].Quests.Type == nil or
		   t[a].Quests.Description == t[b].Quests.Description then
           return t[a].Name < t[b].Name;
        else
           return t[a].Quests.Description < t[b].Quests.Description;
        end
    end

	for minorPlayerID, kCityState in SortedTable( m_kCityStates, SortCityStates) do
		if kCityState.isHasMet and kCityState.Quests.Type ~= nil then
			local questInstance = populateQuest(kCityState);
		end
	end
	print("populateScreen() Done");
end

function SortedTable(t, f)
    local a = {}

    for n in pairs(t) do
        table.insert(a, n)
    end

    if f then
        table.sort(
            a,
            function(k1, k2)
                return f(t, k1, k2)
            end
        )
    else
        table.sort(a)
    end

    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

--Fills m_kCityStates with City-State data
function getData()
	print("getData()");
	local localPlayerID = Game.GetLocalPlayer();
	if (localPlayerID == -1) then return; end

	m_kCityStates = {};		-- Clear any previous data

	local localPlayer:table = Players[localPlayerID];

	--For every city state in the game
	for i, minorPlayer in ipairs(PlayerManager.GetAliveMinors()) do
		local minorPlayerID			:number = minorPlayer:GetID(); 
		local minorPlayerInfluence	:table = minorPlayer:GetInfluence();
		local isHasActiveQuest		:boolean = false;
		
		for questInfo in GameInfo.Quests() do
			isHasActiveQuest = Game.GetQuestsManager():HasActiveQuestFromPlayer( localPlayerID, minorPlayerID, questInfo.Index);
			if ( isHasActiveQuest ) then break; end
		end

		if minorPlayerID ~= localPlayerID and isHasActiveQuest then

			local primaryColor, secondaryColor = UI.GetPlayerColors( minorPlayerID ); 
			local minorPlayerConfig:table = PlayerConfigurations[minorPlayerID]; 

			local kCityState :table		= {
					playerID				= minorPlayerID,
					ColorPrimary			= primaryColor, 
					ColorSecondary			= secondaryColor,
					CivType					= minorPlayerConfig:GetCivilizationTypeName(),
					Name					= minorPlayerConfig:GetCivilizationShortDescription(), 
					isAlive					= minorPlayer:IsAlive(), 
					isHasMet				= localPlayer:GetDiplomacy():HasMet( minorPlayerID ), 
					Quests					= GetQuests( minorPlayerID ),
					EnvoyTokens				= minorPlayerInfluence:GetTokensReceived(localPlayerID)
				};

			m_kCityStates[minorPlayerID] = kCityState;

		end

	end
	print("getData() Done");
end

function GetQuests( playerID:number )
	--print("GetQuests()");
	local kQuests		:table  = {};
	local questsManager	:table = Game.GetQuestsManager();
	local localPlayerID :number = Game.GetLocalPlayer();
	if questsManager ~= nil then
		for questInfo in GameInfo.Quests() do
			if questsManager:HasActiveQuestFromPlayer( localPlayerID, playerID, questInfo.Index) then
				kQuests = { 
					Description = questsManager:GetActiveQuestDescription( localPlayerID, playerID, questInfo.Index),
					Name		= questsManager:GetActiveQuestName( localPlayerID, playerID, questInfo.Index),
					Type		= questInfo.QuestType
				};
					
			end
			
		end
	else
		UI.DataError("City-States were unable to obtain the QuestManager.");
	end
	--print("GetQuests() Done");
	return kQuests;
end

function OnInit(isReload)
    if isReload and not ContextPtr:IsHidden() then
        Open();
    end
end

function OnInputHandler(pInputStruct:table)
    if ContextPtr:IsHidden() then return false; end
    if pInputStruct:GetMessageType() == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE then 
        Close();
    end
    -- Handle all key events so player cannot proceed to next turn through key presses.
    return true;
end

function OnShutdown()
    -- LUA Events
    LuaEvents.EQL_ToggleQuestPopup.Remove(ToggleQuestPopup);
end

function ToggleQuestPopup()
    if ContextPtr:IsHidden() then
        Open();
    else
        Close();
    end
end

function EQL_Initialize()
    ContextPtr:SetInitHandler(OnInit);
    ContextPtr:SetInputHandler(OnInputHandler, true);
    ContextPtr:SetShutdown(OnShutdown);

    LuaEvents.EQL_ToggleQuestPopup.Add(ToggleQuestPopup);

    Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, Close);
    Controls.ModalScreenTitle:SetText(Locale.ToUpper(Locale.Lookup("Envoy Quests")));

    m_TopPanelConsideredHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET;

	Events.InputActionTriggered.Add(OnInputActionTriggered);
end

EQL_Initialize();