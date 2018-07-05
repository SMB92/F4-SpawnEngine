;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_RSEvents Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
if MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.SetMenuVars("RegionSwarmChance")

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.MenuCurrentRegionScript.SetMenuVars("RegionSwarmChance")

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
if MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.SetMenuVars("RegionRampageChance")

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.MenuCurrentRegionScript.SetMenuVars("RegionRampageChance")

endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
if MasterScript.iMenuSettingsMode == 0 ;Master Mode, apply to all

	MasterScript.SetMenuVars("RegionAmbushChance")

elseif MasterScript.iMenuSettingsMode == 1 ;Regional Mode, apply to Region only

	MasterScript.MenuCurrentRegionScript.SetMenuVars("RegionAmbushChance")

endif
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

SOTC:MasterQuestScript Property MasterScript Auto Const
