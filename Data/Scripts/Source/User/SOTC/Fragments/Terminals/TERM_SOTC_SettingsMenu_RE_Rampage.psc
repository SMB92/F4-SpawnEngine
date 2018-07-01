;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_RE_Rampage Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 0)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 0)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 5)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 5)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 10)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 10)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 15)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 15)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 20)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 20)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 25)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 25)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 30)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 30)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 35)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 35)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_09
Function Fragment_Terminal_09(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 40)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 40)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_10
Function Fragment_Terminal_10(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 45)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 45)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_11
Function Fragment_Terminal_11(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 50)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 50)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_12
Function Fragment_Terminal_12(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 55)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 55)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_13
Function Fragment_Terminal_13(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 60)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 60)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_14
Function Fragment_Terminal_14(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 65)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 65)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_15
Function Fragment_Terminal_15(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 70)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 70)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_16
Function Fragment_Terminal_16(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 75)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 75)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_17
Function Fragment_Terminal_17(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 80)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 80)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_18
Function Fragment_Terminal_18(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 85)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 85)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_19
Function Fragment_Terminal_19(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 90)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 90)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_20
Function Fragment_Terminal_20(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 95)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 95)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_21
Function Fragment_Terminal_21(ObjectReference akTerminalRef)
;BEGIN CODE
if (SOTC_Global_MenuSettingsMode.GetValue()) == 0.0

	(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RegionRampageChance", true, 0)
	
else ;Outright assume 1.0 value, Region mode. 

	(SOTC_MasterQuest as SOTC:MasterQuestScript).MenuCurrentRegionScript.SetMenuVars("RegionRampageChance", true, 100)
	
endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_MasterQuest Auto Const

GlobalVariable Property SOTC_Global_MenuSettingsMode Auto Const
