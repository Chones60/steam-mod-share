print("WhatDidIPromise: Loading AKWDIP_TroopsPromiseLense.lua")
if ExposedMembers.AKWDIP_Options ~= nil then 
	opt = ExposedMembers.AKWDIP_Options 
else
	include("AKWDIP_DefaultOptions.lua")
end
include("AKWDIP_Common.lua")


include("LensSupport")

local isCQUIorML = (playerCanHave  ~= nil)

if isCQUI or isMoreLenses then
	print("WhatDidIPromise: AKWDIP_TroopsPromiseLense: We appear to have ML or CQUI")
else
	print("WhatDidIPromise: AKWDIP_TroopsPromiseLense: No ML or CQUI - no military promise lens for you!")
end


local LENS_NAME = "AKWDIP_TROOPSPROMISE"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")
local m_HighlightColour = UI.GetColorValue(1,0,0,0.5)


local function plotIsInPromiseZone(pPlot:table)
	--plot is within 2 tiles of a civ with a promise
	if pPlot:GetOwner() == Game.GetLocalPlayer() then 
		return false;
	end
	
	local ActiveTroopPromises = GetPromisesOfTypeFromPlayerID("KEEP_TROOPS_AWAY_FROM_ME", Game.GetLocalPlayer())
	local PlayersWithActiveTroopPromises = {}
	for _,promise in pairs(ActiveTroopPromises) do
--		if checkForNearbyTilesOwnedBy(promise.Requestor, pPlot, 2) then 
--			return true
--		end	

		for plotID, plotXY in pairs(GetDMZPlotXYsForPlayerID(promise.Requestor)) do
			if pPlot:GetIndex() == plotID then
				return true
			end
		end
	end
	return false
end

local function OnGetColorPlotTable()
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer   :number = Game.GetLocalPlayer()
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local PromiseZoneColor = m_HighlightColour
    local IgnoreColor = UI.GetColorValue("COLOR_MORELENSES_GREY")
    local colorPlot:table = {}
    colorPlot[PromiseZoneColor] = {}
    colorPlot[IgnoreColor] = {}

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            if plotIsInPromiseZone(pPlot) then
                table.insert(colorPlot[PromiseZoneColor], i)
            else
                table.insert(colorPlot[IgnoreColor], i)
            end
        end
    end

    return colorPlot
end

local MilitaryPromiseLensEntry = {
    LensButtonText = "LOC_AKWDIP_HUD_TROOPSPROMISE_LENS"
    ,LensButtonTooltip = "LOC_AKWDIP_HUD_TROOPSPROMISE_LENS_TOOLTIP"
    ,Initialize = nil
    ,GetColorPlotTable = OnGetColorPlotTable
    }

local MilitaryPromiseModalPanelEntry = {
	LensTextKey = "LOC_AKWDIP_HUD_TROOPSPROMISE_LENS"
    ,Legend = { {Locale.Lookup("LOC_AKWDIP_HUD_TROOPSPROMISE_LENS_LEGEND"), m_HighlightColour}}
    }

local function Initialize()
	if isCQUI or isMoreLenses then 
		if g_ModLensModalPanel ~= nil then
			dprint("AKWDIP_TroopsPromiseLense.lua: ", "ModPanelContext")
			g_ModLensModalPanel[LENS_NAME] = MilitaryPromiseModalPanelEntry
			LuaEvents.ModalLensPanel_AddLensEntry(LENS_NAME, MilitaryPromiseModalPanelEntry, true)
		elseif g_ModLenses ~= nil then
			dprint("AKWDIP_TroopsPromiseLense.lua: ", "MiniMapPanelContext")
			g_ModLenses[LENS_NAME] = MilitaryPromiseLensEntry
			LuaEvents.MinimapPanel_AddLensEntry(LENS_NAME, MilitaryPromiseLensEntry)
		else
			dprint("AKWDIP_TroopsPromiseLense.lua: ", "failed both context checks")
		end
	end
end

Initialize()

