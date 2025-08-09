-- ===========================================================================
--	MEMBERS
-- ===========================================================================
include("WonderBuiltPopup.lua")

print("--------- WonderBuiltPopup ---------")
print('Loading WonderBuiltPopup as base file')
print("-------------------------------------------")

g_kCurrentPopup = {};
-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local Old_ShowPopup = ShowPopup
local Old_StopSound = StopSound
-- ===========================================================================
-- OVERRIDE BASE FUNCTIONS
-- ===========================================================================
function ShowPopup( kData:table )
	g_kCurrentPopup = kData
	Old_ShowPopup(kData)
end

function StopSound()

	local iBuilding = g_kCurrentPopup.buildingIndex
	local sBuilding = GameInfo.Buildings[iBuilding].BuildingType
	local sBuildingSuffix = string.sub(sBuilding, 9, -1)
	print(sBuildingSuffix)
	local sAudioEvent = "Stop_Wonder_Music" .. sBuildingSuffix
	print(sAudioEvent)

	UI.PlaySound(sAudioEvent)
	Old_StopSound()
end
-- ===========================================================================
-- ===========================================================================