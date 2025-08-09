--==========================================================================================================================
-- ICONS
--==========================================================================================================================
-- IconTextureAtlases
-------------------------------------
INSERT INTO IconTextureAtlases
		(Name,										Baseline,	IconSize,	IconsPerRow,	IconsPerColumn,		Filename)
VALUES  ('ICON_ATLAS_SUK_SUA',						6,			22,	 		8,				2,					'Suk_SUA_FontIcons.dds');
-------------------------------------
-- IconDefinitions
-------------------------------------
INSERT INTO IconDefinitions
		(Name,										Atlas, 									'Index')
VALUES  ('SukPressureRight',						'ICON_ATLAS_SUK_SUA',					0),
		('SukPressureLeft',							'ICON_ATLAS_SUK_SUA',					0),

		('ICON_SUK_STAT_CITYSTATES',				'ICON_ATLAS_EXPANSION1_STATS',			9);
--==========================================================================================================================
--==========================================================================================================================