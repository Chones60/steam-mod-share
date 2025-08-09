print("WhatDidIPromise: Loading AKWDIP_MinimapPanel.lua")
if ExposedMembers.AKWDIP_Options ~= nil then 
	opt = ExposedMembers.AKWDIP_Options 
else
	include("AKWDIP_DefaultOptions.lua")
end
include("AKWDIP_Common.lua")

--Hook Function
function AKWDIP_AddPromiseBarredSettleLocations()
    AKWDIP_HookedFunction();
	
	if not opt.HighlightNoSettlePromisePlotsOnSettlerLense then 
		return
	end


	local localPlayer = Game.GetLocalPlayer();
	local promiseZoneColor : number = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity")
	
    local FullWaterPlots:table = {};
    local CoastalWaterPlots:table = {};
    local NoWaterPlots:table = {};
    local NoSettlePlots:table = {}; 

	local PromiseBarredPlots = {}

	FullWaterPlots, CoastalWaterPlots, NoWaterPlots, NoSettlePlots = Map.GetContinentPlotsWaterAvailability();	

	local AllContinentPlots = {}
	AllContinentPlots = TableConcat(AllContinentPlots, FullWaterPlots)
	AllContinentPlots = TableConcat(AllContinentPlots, CoastalWaterPlots)
	AllContinentPlots = TableConcat(AllContinentPlots, NoWaterPlots)
	
	local PromiseBarredSettleColour = UI.GetColorValue(1,1,0,0.3);
	
	
	local ActiveNoSettlePromises = GetPromisesOfTypeFromPlayerID("DONT_SETTLE_NEAR_ME", localPlayer)
	local PlayersWithActiveNoSettlePromises = {}
	for _, promise in ipairs(ActiveNoSettlePromises) do 
		table.insert(PlayersWithActiveNoSettlePromises, promise.Requestor)
	end
	

	for _, plotindex in ipairs(AllContinentPlots) do
		plot = Map.GetPlotByIndex(plotindex)
		if plot then 
			local nearbycityowners = findNearbyCityOwners(plot, 8, PlayersWithActiveNoSettlePromises)
			if #nearbycityowners > 0 then 
				table.insert(PromiseBarredPlots, plotindex)
			end
		end
	end
	
	--print("#AllContinentPlots:", #AllContinentPlots)
	--print("#PromiseBarredPlots:", #PromiseBarredPlots)
	
    if(table.count(PromiseBarredPlots) > 0) then
        UILens.SetLayerHexesColoredArea( promiseZoneColor, localPlayer, PromiseBarredPlots, PromiseBarredSettleColour );
    end	


end

--deal with variety of possible base MinimapPanel.lua's we can support
--CQUI and ML replace MinimapPanel.lua in place so don't have to do anything special
local AKDWDIP_Possiblebasefiles = {
	"MinimapPanel_Expansion2.lua"
	,"MinimapPanel_Expansion1.lua"
	,"MinimapPanel.lua"
}

for _, file in ipairs(AKDWDIP_Possiblebasefiles) do
    include(file);
    if Initialize then
        print("WhatDidIPromise: AKWDIP_MinimapPanel.lua using " .. file .. " as base file");
        break;
    end
end

--Override Settler lense PlotEvaluation
if isCQUI or isMoreLenses  then
	print("WhatDidIPromise: Looks like MoreLenses or CQUI")
	AKWDIP_HookedFunction = SetDefaultWaterHexes
	SetDefaultWaterHexes = AKWDIP_AddPromiseBarredSettleLocations
else
	print("WhatDidIPromise: More Lenses or CQUI not detected")
	AKWDIP_HookedFunction = SetWaterHexes
	SetWaterHexes = AKWDIP_AddPromiseBarredSettleLocations
end

--Add MilitaryPromiseLense
--This is deliberately not named to match MLs convention of
--ModLens_* to prevent ML autoloading it
--Like this it is loaded the same way (and correctly) for both ML and CQUI
include("AKWDIP_TroopsPromiseLense.lua")




