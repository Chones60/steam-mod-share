-- ===========================================================================
-- Adjaceny Bonuses for City Districts
-- ===========================================================================
include("InstanceManager");
include("SupportFunctions");

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local PADDING_X :number = 18;
local PADDING_Y :number = 16;

local m_HexColoringAppeal : number = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level");

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_PlotBonusIM	:table = InstanceManager:new( "AppealInstance",	"Anchor", Controls.PlotAppealContainer );
local m_MapIcons	:table = {};

IsChangedMapParent = false;
m_IsAppealLens = true;

--************************************************************
-- Place pin container on the map Z level
local function ChangeParentMap()
	if not IsChangedMapParent then
		local wvc:table = ContextPtr:LookUpControl("/InGame/WorldViewControls"); -- world view
		if wvc ~= nil then
			Controls.PlotAppealContainer:ChangeParent(wvc);
			--tPanRightStack:AddChildAtIndex(Controls.RmtLaunchBarBtn, 3);
			--tPanRightStack:CalculateSize();
			--tPanRightStack:ReprocessAnchoring();
			IsChangedMapParent = true;
		end
	end
end

--************************************************************
-- Callaback of the load game UI event
local function OnLoadGameViewStateDone()
	ChangeParentMap();
end

-- ===========================================================================
function RealizeIconStack(instance:table)
	instance.IconStack:CalculateSize();
	instance.IconStack:ReprocessAnchoring();
end

-- ===========================================================================
function GetInstanceAt( plotIndex:number )
	local pInstance:table = m_MapIcons[plotIndex];
	if pInstance == nil then
		pInstance = m_PlotBonusIM:GetInstance();
		m_MapIcons[plotIndex] = pInstance;
		local worldX:number, worldY:number = UI.GridToWorld( plotIndex );
		-- pInstance.Anchor:SetWorldPositionVal( worldX, worldY, 0 );
		pInstance.Anchor:SetWorldPositionVal( worldX, worldY - 17, 0 );
	end
	return pInstance;
end

-- ===========================================================================
--	Clear all graphics and all district yield icons for all layers.
-- ===========================================================================
function ClearEveything()
	for key,pInstance in pairs(m_MapIcons) do
		m_PlotBonusIM:ReleaseInstance( pInstance );
		m_MapIcons[key]		 = nil;
	end	
end

-- ===========================================================================
function RealizeAppealTiles()
	for i, ContinentID in ipairs(Map.GetContinentsInUse()) do
		ProcessPlots(Map.GetVisibleContinentPlots(ContinentID));
	end
end

-- ===========================================================================
function ProcessPlots(plots:table)
	if plots == nil then
		return;
	end

	for i,plotID in ipairs(plots) do
		print(plotID)
		local kPlot:table = Map.GetPlotByIndex(plotID);
		if kPlot == nil then
			UI.DataError("Bad plot index; could not get plot #"..tostring(plotID));
		else
			if (not kPlot:IsLake()) and (not kPlot:IsMountain()) then
				local instance:table = GetInstanceAt(plotID);
				local appeal = kPlot:GetAppeal();
				local appeal_str = tostring(appeal);
				if appeal > 0 then
					appeal_str = '+' .. appeal_str
				end
				local appeal_text = appeal_str
				if appeal > 0 then
					appeal_text = '[COLOR:ResCultureLabelCS]' .. appeal_str .. '[ENDCOLOR]';
				end
				-- if appeal < 0 then
				-- 	appeal_text = '[COLOR:ResProductionLabelCS]' .. appeal_str .. '[ENDCOLOR]';
				-- end
				-- print(appeal)
				-- instance.PlotAppeal:SetHide(false);
				-- instance.BonusText:SetText(appeal);
				instance.PrereqIcon:SetHide(false);
				instance.PlotBonus:SetHide(false);

				instance.BonusText:SetText(appeal_text);
				local x,y = instance.BonusText:GetSizeVal();
				instance.PlotBonus:SetSizeVal( x+PADDING_X, y+PADDING_Y );

				-- apply an adjustment to prevent overlapping resource icons
				instance.PlotBonus:SetOffsetY(-48);
				instance.PrereqIcon:SetOffsetY(-48);
				RealizeIconStack(instance);
			end
		end
	end
end

-- ===========================================================================
function RemoveAppealTiles()
	for key, pInstance in pairs(m_MapIcons) do
		m_PlotBonusIM:ReleaseInstance( pInstance );
		m_MapIcons[key] = nil;
	end
end

-- ===========================================================================
--	UI Event
--	Handle the UI shutting down.
-- ===========================================================================
function OnShutdown()
	ClearEveything();
	m_PlotBonusIM:DestroyInstances();
	IsChangedMapParent = false;

	-- Game Events
	Events.LensLayerOn.Remove( OnLensLayerOn );
	Events.LensLayerOff.Remove( OnLensLayerOff );
end

-- ===========================================================================
--	Gamecore Event
-- ===========================================================================
function OnLensLayerOn( layerNum:number )	
	if not (layerNum == m_HexColoringAppeal) or (not m_IsAppealLens) then 
		return; 
	end
	RealizeAppealTiles();
end

-- ===========================================================================
--	Gamecore Event
-- ===========================================================================
function OnLensLayerOff( layerNum:number )
	if not (layerNum == m_HexColoringAppeal) or (not m_IsAppealLens) then 
		return; 
	end
	RemoveAppealTiles();
end

function OnMinimapPanel_ModdedLensOn( lensName )
	if lensName == 'VANILLA_APPEAL' then
		m_IsAppealLens = true;
	else
		m_IsAppealLens = false;
		RemoveAppealTiles();
	end
end

-- ===========================================================================
--	
-- ===========================================================================
function Initialize()
	print('Loading Detailed Appeal Lens');

	-- UI Events
	-- ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetShutdown( OnShutdown );
	Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone);

	-- Game Events
	Events.LensLayerOn.Add( OnLensLayerOn );
	Events.LensLayerOff.Add( OnLensLayerOff );
	-- Events.PlotVisibilityChanged.Add( OnPlotVisibilityChanged );
	LuaEvents.MinimapPanel_ModdedLensOn.Add(OnMinimapPanel_ModdedLensOn);
end
Initialize();
