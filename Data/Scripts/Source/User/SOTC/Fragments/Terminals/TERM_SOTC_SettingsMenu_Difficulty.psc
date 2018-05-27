;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_Difficulty Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.iCurrentDifficulty = 0
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.MenuCurrentRegionScript.iCurrentDifficulty = 0

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.iCurrentDifficulty = 1
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.MenuCurrentRegionScript.iCurrentDifficulty = 1

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.iCurrentDifficulty = 2
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.MenuCurrentRegionScript.iCurrentDifficulty = 2

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.iCurrentDifficulty = 3
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.MenuCurrentRegionScript.iCurrentDifficulty = 3

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment

If MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.iCurrentDifficulty = 4 ;YES 4 = NONE IN BETHESDA LAND :D
	MasterScript.SendMasterSingleSettingUpdateEvent("Difficulty", false, 0, 0.0)

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.MenuCurrentRegionScript.iCurrentDifficulty = 4

endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property MasterQuest Auto Const
