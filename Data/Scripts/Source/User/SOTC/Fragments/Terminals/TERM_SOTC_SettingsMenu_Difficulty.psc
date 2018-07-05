;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_Difficulty Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(2)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(3)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(4)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

SOTC:MasterQuestScript Property MasterScript Auto Const

Function UpdateMenuVars(Int aiValue01)

	if MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

		MasterScript.SetMenuVars("MasterDifficulty", true, aiValue01)

	elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

		MasterScript.MenuCurrentRegionScript.SetMenuVars("RegionDifficulty", true, aiValue01)

	endif
	
EndFunction
