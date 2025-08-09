local m_LaunchButtonInstance = {};

function ToggleQuestPopup()
	LuaEvents.EQL_ToggleQuestPopup();
end

function AttachLaunchButton()
	
	local buttonStack = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack");

	ContextPtr:BuildInstanceForControl("LaunchBarItem", m_LaunchButtonInstance, buttonStack);
	m_LaunchButtonInstance.LaunchItemButton:RegisterCallback(Mouse.eLClick, ToggleQuestPopup);
	m_LaunchButtonInstance.LaunchItemIcon:SetTexture(IconManager:FindIconAtlas("ICON_LAUNCHBUTTON_EQL", 36));

	ContextPtr:BuildInstanceForControl("LaunchBarPinInstance", {}, buttonStack);

	--Resize
	buttonStack:CalculateSize();

	local backing = ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBacking");
    backing:SetSizeX(buttonStack:GetSizeX() + 116);

	local backingTile = ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBackingTile");
    backingTile:SetSizeX(buttonStack:GetSizeX() - 20);

	LuaEvents.LaunchBar_Resize(buttonStack:GetSizeX());
end

function OnLoadGameViewStateDone()
    AttachLaunchButton();
end

function EQL_Initialize()
    Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone);
end

EQL_Initialize();