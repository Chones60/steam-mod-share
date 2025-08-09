print("WhatDidIPromise: Loading AKWDIP_ModalLensPanel.lua")
if ExposedMembers.AKWDIP_Options ~= nil then 
	opt = ExposedMembers.AKWDIP_Options 
else
	include("AKWDIP_DefaultOptions.lua")
end
include("AKWDIP_Common.lua")


function AKWDIP_ShowSettlerLensKey()
    AKWDIP_HookedFunction();

	if not opt.HighlightNoSettlePromisePlotsOnSettlerLense then 
		return
	end
	
	AddKeyEntry(Locale.Lookup("LOC_AKWDIP_HUD_SETTLEPROMISE_LENS_LEGEND"), UI.GetColorValue(1,1,0,0.5));
end


--deal with variety of possible base ModalLensPanel.lua's we can support
--CQUI and ML replace ModalLensPanel.lua in place so don't have to do anything special
local AKDWDIP_Possiblebasefiles = {
	"ModalLensPanel_Expansion2.lua"
	,"ModalLensPanel_Expansion1.lua"
	,"ModalLensPanel.lua"}

for _, file in ipairs(AKDWDIP_Possiblebasefiles) do
    include(file);
    if Initialize then
        print("WhatDidIPromise: AKWDIP_ModalLensPanel.lua using " .. file .. " as base file");
        break;
    end
end


AKWDIP_HookedFunction = ShowSettlerLensKey
ShowSettlerLensKey = AKWDIP_ShowSettlerLensKey

--Add MilitaryPromiseLenseModalPanel
--This is deliberately not named to match MLs convention of
--ModLens_* to prevent ML autoloading it
--Like this it is loaded the same way (and correctly) for both ML and CQUI
include("AKWDIP_TroopsPromiseLense.lua")

