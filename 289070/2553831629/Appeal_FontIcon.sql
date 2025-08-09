--==========================================================================================================================
-- ICONS
--==========================================================================================================================
-- IconTextureAtlases
	
INSERT INTO IconTextureAtlases	
		(Name,										IconSize,	IconsPerRow,	IconsPerColumn,		Baseline,		Filename)
VALUES  ('ICON_ATLAS_APPEAL_FONTICON',				22,		 	1,				1,					6,				'AppealFontIcon_22.dds');

-- IconDefinitions

INSERT OR REPLACE INTO IconDefinitions	
		(Name,											Atlas, 											'Index')
VALUES  ('ICON_STAT_APPEAL',							'ICON_ATLAS_APPEAL_FONTICON',					0);
--==========================================================================================================================
--==========================================================================================================================