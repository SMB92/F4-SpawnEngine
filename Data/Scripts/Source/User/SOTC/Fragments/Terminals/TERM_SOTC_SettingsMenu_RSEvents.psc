;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_RSEvents Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionSwarmChance")
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionSwarmChance")
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance")
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance")
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionAmbushChance")
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionAmbushChance")
	
endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_MasterQuest Auto Const

GlobalVariable Property SOTC_Global_MenuSettingsMode Auto Const
