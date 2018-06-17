;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_Difficulty Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment without hassle

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.SetMenuVars("MasterDifficulty", true, 0)
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.SetMenuVars("RegionDifficulty", true, 0)

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment without hassle

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.SetMenuVars("MasterDifficulty", true, 1)
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.SetMenuVars("RegionDifficulty", true, 1)

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment without hassle

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.SetMenuVars("MasterDifficulty", true, 2)
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.SetMenuVars("RegionDifficulty", true, 2)

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment without hassle

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.SetMenuVars("MasterDifficulty", true, 3)
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.SetMenuVars("RegionDifficulty", true, 3)

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment without hassle

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.SetMenuVars("MasterDifficulty", true, 4)
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.SetMenuVars("RegionDifficulty", true, 4)

endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property MasterQuest Auto Const
