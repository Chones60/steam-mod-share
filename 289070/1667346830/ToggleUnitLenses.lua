-- ===========================================================================
--	Toggle Unit Lenses
-- ===========================================================================

local m_HexColoringWaterAvail : number = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity");

function OnToggleUnitLense()
	local pUnit :table = UI.GetHeadSelectedUnit();
	if( pUnit == nil ) then
		return;
	end
  
	local bPlaySound :boolean = true;
	local religiousStrength :number = pUnit:GetReligiousStrength();
	
	if( GameInfo.Units[pUnit:GetUnitType()].FoundCity ) then
		if UILens.IsLayerOn( m_HexColoringWaterAvail ) then
			UILens.ToggleLayerOff(m_HexColoringWaterAvail);
		else
			UILens.ToggleLayerOn(m_HexColoringWaterAvail);
		end
	elseif( religiousStrength > 0 ) then
		if UILens.IsLensActive("Religion") then
			UILens.SetActive("Default");
		else
			UILens.SetActive("Religion");
		end
	else
		bPlaySound = false
	end
  
	if( bPlaySound ) then
		UI.PlaySound("Play_UI_Click");	
	end
end

function OnIngameAction(actionId)
	if (Game.GetLocalPlayer() == -1) then
		return;
	end
	if actionId == Input.GetActionId("ToggleUnitLense") then
		OnToggleUnitLense();
	end
end


-- ===========================================================================
-- INITIALIZATION
-- ===========================================================================
function OnInit( isReload:boolean )

end

function OnShutdown()
	Events.InputActionTriggered.Remove( OnIngameAction );
end

function Initialize()
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetShutdown( OnShutdown );
	Events.InputActionTriggered.Add( OnIngameAction );
end
Initialize();
