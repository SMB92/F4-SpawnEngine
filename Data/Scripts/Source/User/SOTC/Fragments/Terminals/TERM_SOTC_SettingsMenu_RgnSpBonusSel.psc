;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_RgnSpBonusSel Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC_Global01.SetValue(1.0)

if MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all
	MasterScript.SetMenuVars("SpPresetChanceBonus")
else ;Assume 1.0
	MasterScript.MenuCurrentRegionScript.SetMenuVars("SpPresetChanceBonus")
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC_Global01.SetValue(2.0)

if MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all
	MasterScript.SetMenuVars("SpPresetChanceBonus")
else ;Assume 1.0
	MasterScript.MenuCurrentRegionScript.SetMenuVars("SpPresetChanceBonus")
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC_Global01.SetValue(3.0)

if MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all
	MasterScript.SetMenuVars("SpPresetChanceBonus")
else ;Assume 1.0
	MasterScript.MenuCurrentRegionScript.SetMenuVars("SpPresetChanceBonus")
endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

GlobalVariable Property SOTC_Global01 Auto Const

SOTC:MasterQuestScript Property MasterScript Auto Const
